//-----------------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                           //
// The core functionality of this plugin's code originated in https://github.com/jongpie/ApexValidationRules //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.               //
//-----------------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Evaluates an `SObject` record to see if it matches the condition(s) defined in `LogRetentionRule__mdt` and its related
 *              list of related `LogRetentionRuleCondition__mdt` records. The result is then used in `LogRententionRulesPlugin` to override
 *              the value of `Log__c.LogRetentionDate__c` for any records that match the filters.
 * @see LogRententionRulesPlugin
 */
@SuppressWarnings('PMD.CognitiveComplexity')
public without sharing class LogRetentionFilter {
  private final SObject record;
  private final LogRetentionRule__mdt rule;
  private final List<LogRetentionRuleCondition__mdt> ruleFilterConditions;

  /**
   * @description Creates a new instance of `LogRetentionFilter`, used to determine if an `SObject` record
   *              meets the criteria of the provided rule & filter conditions
   * @param  record           The `SObject` record to compare
   * @param  rule             The filter rule to apply to the `SObject` record, stored as an instance of `LogRetentionRule__mdt`
   * @param  ruleFilterConditions The list of `LogRetentionRuleCondition__mdt` for the rule that should be applied to the `SObject` record
   */
  public LogRetentionFilter(SObject record, LogRetentionRule__mdt rule, List<LogRetentionRuleCondition__mdt> ruleFilterConditions) {
    this.record = record;
    this.rule = rule;
    this.ruleFilterConditions = ruleFilterConditions;
  }

  /**
   * @description Returns an instance of `FilterResult` that provides information regarding
   *              if the `SObject` record matches the provided rule & filter conditions
   * @return   The new instance of `FilterResult`
   */
  public FilterResult getFilterResult() {
    return new FilterResult(this.record, this.rule, this.ruleFilterConditions);
  }

  /**
   * @description Inner class used to handle determining if the provided `SObject` record meets
   *              the criteria for the provided `LogRetentionRule__mdt` rule and associated `List<LogRetentionRuleCondition__mdt>` ruleFilterConditions
   */
  public class FilterResult {
    private List<String> conditions;
    private String conditionsLogic;
    private String conditionsLogicType;
    private Boolean matchesFilter;
    private SObject record;
    private LogRetentionRule__mdt rule;
    private List<LogRetentionRuleCondition__mdt> ruleFilterConditions;

    private FilterResult(SObject record, LogRetentionRule__mdt rule, List<LogRetentionRuleCondition__mdt> ruleFilterConditions) {
      this.record = record;
      this.rule = rule;
      this.ruleFilterConditions = ruleFilterConditions;
      this.conditions = new List<String>();
      this.conditionsLogic = this.getRuleFilterConditionsLogic();
      this.conditionsLogicType = rule.ConditionLogicType__c;

      this.process();
    }

    /**
     * @description Returns the `LogRetentionRule__mdt` rule that was used to create the instance of `FilterResult`
     * @return   The instance of `LogRetentionRule__mdt`
     */
    public LogRetentionRule__mdt getRule() {
      return this.rule;
    }

    /**
     * @description Returns the `SObject` record that was used to create the instance of `FilterResult`
     * @return   The instance of `SObject`
     */
    public SObject getRecord() {
      return this.record;
    }

    /**
     * @description Indicates if the provided `SObject` record matches all of the criteria defined in
     *              the `LogRetentionRule__mdt` rule and associated `List<LogRetentionRuleCondition__mdt>` ruleFilterConditions
     * @return   The `Boolean` value that indicates if the `SObject` record matches the provided rule & conditions (`true`)
     *           or if the record does not match the rule & conditions (`false`)
     */
    public Boolean matchesFilter() {
      return this.matchesFilter;
    }

    private void process() {
      List<String> booleanValues = new List<String>();
      for (LogRetentionRuleCondition__mdt filterCondition : this.ruleFilterConditions) {
        FilterConditionResult filterConditionResult = new FilterConditionResult(this.record, filterCondition);
        this.conditions.add(filterConditionResult.getCondition());
        booleanValues.add(String.valueOf(filterConditionResult.matchesFilter));
      }

      String parsedConditionsLogic = String.format(this.getRuleFilterConditionsLogic(), booleanValues);

      this.matchesFilter = new BooleanExpression().evaluate(parsedConditionsLogic);
    }

    @SuppressWarnings('PMD.CyclomaticComplexity')
    private String getRuleFilterConditionsLogic() {
      String conditionsLogic = String.isBlank(this.rule.CustomConditionLogic__c) ? '' : this.rule.CustomConditionLogic__c;

      if (this.rule.ConditionLogicType__c != 'Custom') {
        List<String> standardLogicPieces = new List<String>();
        for (Integer i = 0; i < this.ruleFilterConditions.size(); i++) {
          standardLogicPieces.add(String.valueOf(i + 1));
        }
        conditionsLogic = '(' + String.join(standardLogicPieces, ' ' + this.rule.ConditionLogicType__c + ' ') + ')';
      }

      List<String> parsedCharacters = new List<String>();
      Boolean hasFoundNumbers = false;
      String foundNumberString = '';

      for (String character : conditionsLogic.split('')) {
        if (!character.isNumeric() && !hasFoundNumbers) {
          parsedCharacters.add(character);
        } else if (!character.isNumeric() && hasFoundNumbers) {
          hasFoundNumbers = false;
          Integer foundNumber = Integer.valueOf(foundNumberString) - 1;

          parsedCharacters.add('{' + foundNumber + '}');
          foundNumberString = '';
          parsedCharacters.add(character);
        } else if (character.isNumeric()) {
          hasFoundNumbers = true;
          foundNumberString += character;
        } else if (hasFoundNumbers && !character.isNumeric() && !String.isBlank(foundNumberString)) {
          Integer foundNumber = Integer.valueOf(foundNumberString) - 1;

          parsedCharacters.add('{' + foundNumber + '}');
          foundNumberString = '';
        } else {
          parsedCharacters.add(character);
        }
      }
      return String.join(parsedCharacters, '').toUpperCase();
    }
  }

  @SuppressWarnings('PMD.ApexDoc')
  @TestVisible
  private class FilterConditionResult {
    private Boolean matchesFilter;
    private SObject record;
    private LogRetentionRuleCondition__mdt filterCondition;
    private Schema.SObjectType sobjectType;

    private FilterConditionResult(SObject record, LogRetentionRuleCondition__mdt filterCondition) {
      this.sobjectType = record.getSObjectType();
      this.record = record;
      this.filterCondition = filterCondition;

      this.matchesFilter = this.matchesFilter();
    }

    public String getCondition() {
      return this.filterCondition.FieldPath__c +
        ' ' +
        this.filterCondition.Operator__c +
        ' ' +
        this.getComparisonValue() +
        ' (' +
        this.filterCondition.ValueType__c +
        ')';
    }

    public Boolean matchesFilter() {
      // TODO In a future release, it'd be great to switch to using a new private enum for ValueType__c values
      if (this.filterCondition.ValueType__c == 'RegEx') {
        return this.matchesRegEx();
      }

      Schema.SObjectField field = new FieldPath(this.sobjectType, this.filterCondition.FieldPath__c).getField();

      Object recordFieldValue = this.getFieldValue();
      Object comparisonValue = this.getComparisonValue();

      switch on field.getDescribe().getSoapType() {
        when DATETIME {
          return this.compareDatetime((Datetime) recordFieldValue, this.getAsDatetime(comparisonValue));
        }
        when DOUBLE, INTEGER {
          return this.compareDecimal((Decimal) recordFieldValue, this.getAsDecimal(comparisonValue));
        }
        when STRING, ID {
          return this.compareString((String) recordFieldValue, String.valueOf(comparisonValue));
        }
        when else {
          throw new System.IllegalArgumentException('Could not process field path: ' + this.filterCondition.FieldPath__c);
        }
      }
    }

    private Boolean matchesRegEx() {
      System.Pattern pattern = System.Pattern.compile(this.filterCondition.Value__c);
      return pattern.matcher(String.valueOf(this.getFieldValue())).matches();
    }

    private Object getFieldValue() {
      return new FieldPath(this.sobjectType, this.filterCondition.FieldPath__c).getValue(this.record);
    }

    private Object getComparisonValue() {
      switch on this.filterCondition.ValueType__c {
        when 'Field' {
          return new FieldPath(this.sobjectType, this.filterCondition.Value__c).getValue(this.record);
        }
        when 'RegEx' {
          return this.filterCondition.Value__c;
        }
        when 'Value' {
          return this.filterCondition.Value__c;
        }
        when else {
          throw new System.IllegalArgumentException('Unknown Value Type, cannot parse comparison value');
        }
      }
    }

    // Helper methods for dealing with converting field values & strings
    // (stored in CMDT) to the appropriate data type
    private Datetime getAsDatetime(Object datetimeValue) {
      if (datetimeValue == null) {
        return null;
      } else if (datetimeValue instanceof Datetime) {
        return (Datetime) datetimeValue;
      } else {
        String datetimeString = (String) datetimeValue;
        return (Datetime) System.JSON.deserialize(datetimeString, Datetime.class);
      }
    }

    private Decimal getAsDecimal(Object decimalValue) {
      if (decimalValue == null) {
        return null;
      } else if (decimalValue instanceof Decimal) {
        return (Decimal) decimalValue;
      } else {
        String decimalString = (String) decimalValue;
        return (Decimal) System.JSON.deserialize(decimalString, Decimal.class);
      }
    }

    // In Apex, you can't use comparison operators on instances of Object, so several private methods are used for each data type
    // Example of what you can't do in Apex:
    //          Object today = System.today();
    //          Object yesterday = System.today().addDays(-1);
    //          System.Assert.isTrue(today > yesterday); // This line cannot execute since it's comparing Object
    private Boolean compareDatetime(Datetime recordFieldValue, Datetime comparisonValue) {
      // TODO In a future release, it'd be great to switch (ha!) these hardcoded strings to instead use
      // a (new) private enum
      switch on this.filterCondition.Operator__c {
        when 'EQUAL_TO' {
          return recordFieldValue == comparisonValue;
        }
        when 'NOT_EQUAL_TO' {
          return recordFieldValue != comparisonValue;
        }
        when 'LESS_THAN' {
          return recordFieldValue < comparisonValue;
        }
        when 'LESS_THAN_OR_EQUAL_TO' {
          return recordFieldValue <= comparisonValue;
        }
        when 'GREATER_THAN' {
          return recordFieldValue > comparisonValue;
        }
        when 'GREATER_THAN_OR_EQUAL_TO' {
          return recordFieldValue >= comparisonValue;
        }
        when else {
          throw new System.IllegalArgumentException('Unsupported operator for Datetime: ' + this.filterCondition.Operator__c);
        }
      }
    }

    private Boolean compareDecimal(Decimal recordFieldValue, Decimal comparisonValue) {
      // TODO In a future release, it'd be great to switch (ha!) these hardcoded strings to instead use
      // a (new) private enum
      switch on this.filterCondition.Operator__c {
        when 'EQUAL_TO' {
          return recordFieldValue == comparisonValue;
        }
        when 'NOT_EQUAL_TO' {
          return recordFieldValue != comparisonValue;
        }
        when 'LESS_THAN' {
          return recordFieldValue < comparisonValue;
        }
        when 'LESS_THAN_OR_EQUAL_TO' {
          return recordFieldValue <= comparisonValue;
        }
        when 'GREATER_THAN' {
          return recordFieldValue > comparisonValue;
        }
        when 'GREATER_THAN_OR_EQUAL_TO' {
          return recordFieldValue >= comparisonValue;
        }
        when else {
          throw new System.IllegalArgumentException('Unsupported operator for Decimal: ' + this.filterCondition.Operator__c);
        }
      }
    }

    private Boolean compareString(String recordFieldValue, String comparisonValue) {
      // TODO In a future release, it'd be great to switch (ha!) these hardcoded strings to instead use
      // a (new) private enum
      switch on this.filterCondition.Operator__c {
        when 'EQUAL_TO' {
          return recordFieldValue == comparisonValue;
        }
        when 'NOT_EQUAL_TO' {
          return recordFieldValue != comparisonValue;
        }
        when 'STARTS_WITH' {
          return recordFieldValue.startsWith(comparisonValue);
        }
        when 'CONTAINS' {
          return recordFieldValue.contains(comparisonValue);
        }
        when 'ENDS_WITH' {
          return recordFieldValue.endsWith(comparisonValue);
        }
        when else {
          throw new System.IllegalArgumentException('Unsupported operator for String: ' + this.filterCondition.Operator__c);
        }
      }
    }
  }

  // Credit goes to this StackExchange post for the original BooleanExpression class -
  // below is a modified version of the class
  // https://salesforce.stackexchange.com/questions/113300/boolean-evaluation-in-apex/113308
  @SuppressWarnings('PMD.ApexDoc')
  private class BooleanExpression {
    public Boolean evaluate(String x) {
      x = simplify(x);

      if (isSimpleExpression(x)) {
        return Boolean.valueOf(x);
      }

      if (x.contains('&&')) {
        return andJoin(x.split('&&', 2)[0], x.split('&&', 2)[1]);
      }

      if (x.contains('||')) {
        String p1 = x.split('\\|\\|', 2)[0];
        String p2 = x.split('\\|\\|', 2)[1];

        return orJoin(p1, p2);
      }

      if (x.startsWith('!')) {
        return !evaluate(x.substring(1));
      }

      return Boolean.valueOf(x);
    }

    private Boolean orJoin(String x, String y) {
      return evaluate(x) || evaluate(y);
    }

    private Boolean andJoin(String x, String y) {
      return evaluate(x) && evaluate(y);
    }

    private Boolean isSimpleExpression(String x) {
      return x == 'true' || x == 'false';
    }

    private String simplify(String x) {
      x = x.trim();
      x = x.replace('AND', '&&');
      x = x.replace('OR', '||');
      while (x.contains('(')) {
        String sub = x.substringAfterLast('(').substringBefore(')');
        x = x.replace('(' + sub + ')', String.valueOf(evaluate(sub)));
      }
      return x;
    }
  }

  @SuppressWarnings('PMD.ApexDoc')
  private class FieldPath {
    private List<Schema.SObjectField> fieldChain;
    private Schema.DescribeFieldResult fieldDescribe;
    private String fieldPath;
    private Schema.SObjectType sobjectType;

    public FieldPath(Schema.SObjectType sobjectType, String fieldPath) {
      this.fieldChain = this.getFieldChain(sobjectType, fieldPath);
      this.fieldPath = fieldPath;

      this.fieldDescribe = this.getLastFieldDescribe();
    }

    public Schema.SObjectField getField() {
      return this.fieldChain[this.fieldChain.size() - 1];
    }

    public Object getValue(SObject record) {
      Schema.SObjectType parentSObjectType = this.sobjectType;
      SObject parentRecord = record;

      for (Schema.SObjectField field : this.fieldChain) {
        Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
        if (fieldDescribe.getSoapType() != Schema.SoapType.ID) {
          return parentRecord.get(fieldDescribe.getName());
        } else {
          parentSObjectType = fieldDescribe.getReferenceTo().get(0);

          SObject newParentRecord = parentRecord.getSObject(field);
          if (newParentRecord == null) {
            return null;
          } else {
            parentRecord = newParentRecord;
          }
        }
      }

      return null;
    }

    private List<Schema.SObjectField> getFieldChain(Schema.SObjectType sobjectType, String fieldPath) {
      Schema.SObjectType currentSObjectType = sobjectType;

      List<Schema.SObjectField> fields = new List<Schema.SObjectField>();
      List<String> fieldPathPieces = fieldPath.split('\\.');
      Integer lastFieldIndex = fieldPathPieces.size() <= 1 ? 0 : fieldPathPieces.size() - 1;

      for (Integer i = 0; i < fieldPathPieces.size(); i++) {
        String fieldPathPiece = fieldPathPieces[i];

        String fieldApiName;
        if (i == lastFieldIndex) {
          fieldApiName = fieldPathPiece;
        } else if (fieldPathPiece.endsWith('__r')) {
          fieldApiName = fieldPathPiece.replace('__r', '__c');
        } else {
          fieldApiName = fieldPathPiece + 'Id';
        }

        Schema.SObjectField field = currentSObjectType.getDescribe().fields.getMap().get(fieldApiName);

        // TODO add support for polymorphic fields
        if (i < lastFieldIndex) {
          currentSObjectType = field.getDescribe().getReferenceTo().get(0);
        }

        fields.add(field);
      }

      return fields;
    }

    private Schema.DescribeFieldResult getLastFieldDescribe() {
      Integer lastFieldIndex = this.fieldChain.size() - 1;
      return this.fieldChain[lastFieldIndex].getDescribe();
    }
  }
}
