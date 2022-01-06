/********************************************************************************************************
 * This file is part of the Apex Validation Rules project, released under the MIT License.              *
 * See LICENSE file or go to https://github.com/jongpie/RecordValidationRules for full license details. *
 *******************************************************************************************************/

@isTest
private class FilteredEventLoggerPlugin_Tests {
    /* static LogEntryEventFilter__mdt createMockRule() {
        return new LogEntryEventFilter__mdt(
            ConditionLogicType__c = 'AND',
            CustomConditionLogic__c = null,
            ErrorMessage__c = 'Whoops, an error occurred',
            IsActive__c = true
        );
    }

    static LogEntryEventFilterCondition__mdt createMockRuleCondition(String fieldPath, String operator, String valueType, Object value) {
        String valueString = value instanceof String ? (String) value : JSON.serialize(value);
        return new LogEntryEventFilterCondition__mdt(
            FieldPath__c = fieldPath,
            Operator__c = operator,
            SortOrder__c = null,
            Value__c = valueString,
            ValueType__c = valueType
        );
    }

    // Simpler tests - each test is for 1 field with a different data type
    @isTest
    static void validateForRuleWithBooleanFieldAndAllOperators() {
        String fieldPath = Schema.User.IsActive.getDescribe().getName();
        Boolean fieldValue = true;
        User record = new User();
        record.put(fieldPath, fieldValue);

        Map<String, Boolean> operatorToValue = new Map<String, Boolean>{ 'EQUAL_TO' => true, 'NOT_EQUAL_TO' => false };
        for (String operator : operatorToValue.keySet()) {
            Boolean value = operatorToValue.get(operator);

            LogEntryEventFilter__mdt rule = createMockRule();
            LogEntryEventFilterCondition__mdt condition = createMockRuleCondition(fieldPath, operator, 'Value', value);
            List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{ condition };

            RecordValidator validator = new RecordValidator(record).setRule(rule, conditions);
            List<RecordValidator.ValidationRuleResult> results = validator.validate(false);
            System.assertEquals(1, results.size(), 'Expected 1 validation rule result: ' + results);

            RecordValidator.ValidationRuleResult result = results.get(0);
            System.assertEquals(true, result.hasError, result);
            System.assertEquals(rule.ErrorMessage__c, result.errorMessage, result);

            try {
                validator.validate();
                System.assert(false, 'Exception expected on line above');
            } catch (RecordValidator.RecordValidatorException ex) {
                System.assert(ex.getMessage().contains(rule.ErrorMessage__c), ex);
            }
        }
    }

    @isTest
    static void validateForRuleWithDateFieldAndAllOperators() {
        String fieldPath = Schema.Opportunity.CloseDate.getDescribe().getName();
        Date fieldValue = System.today();
        Opportunity record = new Opportunity(CloseDate = fieldValue);

        Map<String, Date> operatorToValue = new Map<String, Date>{
            'EQUAL_TO' => fieldValue,
            'NOT_EQUAL_TO' => fieldValue.addDays(10),
            'LESS_THAN' => fieldValue.addDays(10),
            'LESS_THAN_OR_EQUAL_TO' => fieldValue.addDays(10),
            'GREATER_THAN' => fieldValue.addDays(-10),
            'GREATER_THAN_OR_EQUAL_TO' => fieldValue.addDays(-10)
        };
        for (String operator : operatorToValue.keySet()) {
            Date value = operatorToValue.get(operator);

            LogEntryEventFilter__mdt rule = createMockRule();
            LogEntryEventFilterCondition__mdt condition = createMockRuleCondition(fieldPath, operator, 'Value', value);
            List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{ condition };

            RecordValidator validator = new RecordValidator(record).setRule(rule, conditions);
            List<RecordValidator.ValidationRuleResult> results = validator.validate(false);
            System.assertEquals(1, results.size(), 'Expected 1 validation rule result: ' + results);

            RecordValidator.ValidationRuleResult result = results.get(0);
            System.assertEquals(true, result.hasError, result);
            System.assertEquals(rule.ErrorMessage__c, result.errorMessage, result);

            try {
                validator.validate();
                System.assert(false, 'Exception expected on line above');
            } catch (RecordValidator.RecordValidatorException ex) {
                System.assert(ex.getMessage().contains(rule.ErrorMessage__c), ex);
            }
        }
    }

    @isTest
    static void validateForRuleWithDatetimeFieldAndAllOperators() {
        String fieldPath = Schema.Event.ActivityDatetime.getDescribe().getName();
        Datetime fieldValue = System.now().addDays(-3);
        Event record = new Event();
        record.put(fieldPath, fieldValue);

        Map<String, Datetime> operatorToValue = new Map<String, Datetime>{
            'EQUAL_TO' => fieldValue,
            'NOT_EQUAL_TO' => fieldValue.addDays(10),
            'LESS_THAN' => fieldValue.addDays(10),
            'LESS_THAN_OR_EQUAL_TO' => fieldValue.addDays(10),
            'GREATER_THAN' => fieldValue.addDays(-10),
            'GREATER_THAN_OR_EQUAL_TO' => fieldValue.addDays(-10)
        };
        for (String operator : operatorToValue.keySet()) {
            Datetime value = operatorToValue.get(operator);

            LogEntryEventFilter__mdt rule = createMockRule();
            LogEntryEventFilterCondition__mdt condition = createMockRuleCondition(fieldPath, operator, 'Value', value);
            List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{ condition };

            RecordValidator validator = new RecordValidator(record).setRule(rule, conditions);
            List<RecordValidator.ValidationRuleResult> results = validator.validate(false);
            System.assertEquals(1, results.size(), 'Expected 1 validation rule result: ' + results);

            RecordValidator.ValidationRuleResult result = results.get(0);
            System.assertEquals(true, result.hasError, result);
            System.assertEquals(rule.ErrorMessage__c, result.errorMessage, result);

            try {
                validator.validate();
                System.assert(false, 'Exception expected on line above');
            } catch (RecordValidator.RecordValidatorException ex) {
                System.assert(ex.getMessage().contains(rule.ErrorMessage__c), ex);
            }
        }
    }

    @isTest
    static void validateForRuleWithDecimalFieldAndAllOperators() {
        String fieldPath = Schema.Account.AnnualRevenue.getDescribe().getName();
        Decimal fieldValue = 123000.9876;
        Account record = new Account();
        record.put(fieldPath, fieldValue);

        Map<String, Decimal> operatorToValue = new Map<String, Decimal>{
            'EQUAL_TO' => fieldValue,
            'NOT_EQUAL_TO' => fieldValue + 10.99,
            'LESS_THAN' => fieldValue + 10.25,
            'LESS_THAN_OR_EQUAL_TO' => fieldValue + 10.0000001,
            'GREATER_THAN' => fieldValue - 10,
            'GREATER_THAN_OR_EQUAL_TO' => fieldValue - 10
        };
        for (String operator : operatorToValue.keySet()) {
            Decimal value = operatorToValue.get(operator);

            LogEntryEventFilter__mdt rule = createMockRule();
            LogEntryEventFilterCondition__mdt condition = createMockRuleCondition(fieldPath, operator, 'Value', value);
            List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{ condition };

            RecordValidator validator = new RecordValidator(record).setRule(rule, conditions);
            List<RecordValidator.ValidationRuleResult> results = validator.validate(false);
            System.assertEquals(1, results.size(), 'Expected 1 validation rule result: ' + results);

            RecordValidator.ValidationRuleResult result = results.get(0);
            System.assertEquals(true, result.hasError, result);
            System.assertEquals(rule.ErrorMessage__c, result.errorMessage, result);

            try {
                validator.validate();
                System.assert(false, 'Exception expected on line above');
            } catch (RecordValidator.RecordValidatorException ex) {
                System.assert(ex.getMessage().contains(rule.ErrorMessage__c), ex);
            }
        }
    }

    @isTest
    static void validateForRuleWithStringFieldAndAllOperators() {
        String fieldPath = Schema.Account.Name.getDescribe().getName();
        String fieldValue = 'Some account';
        Account record = new Account();
        record.put(fieldPath, fieldValue);

        Map<String, String> operatorToValue = new Map<String, String>{
            'EQUAL_TO' => fieldValue,
            'NOT_EQUAL_TO' => 'something else',
            'STARTS_WITH' => fieldValue.left(3),
            'CONTAINS' => fieldValue.substring(2, 4),
            'ENDS_WITH' => fieldValue.right(3)
        };
        for (String operator : operatorToValue.keySet()) {
            String value = operatorToValue.get(operator);

            LogEntryEventFilter__mdt rule = createMockRule();
            LogEntryEventFilterCondition__mdt condition = createMockRuleCondition(fieldPath, operator, 'Value', value);
            List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{ condition };

            RecordValidator validator = new RecordValidator(record).setRule(rule, conditions);
            List<RecordValidator.ValidationRuleResult> results = validator.validate(false);
            System.assertEquals(1, results.size(), 'Expected 1 validation rule result: ' + results);

            RecordValidator.ValidationRuleResult result = results.get(0);
            System.assertEquals(true, result.hasError, result);
            System.assertEquals(rule.ErrorMessage__c, result.errorMessage, result);

            try {
                validator.validate();
                System.assert(false, 'Exception expected on line above');
            } catch (RecordValidator.RecordValidatorException ex) {
                System.assert(ex.getMessage().contains(rule.ErrorMessage__c), ex);
            }
        }
    }

    @isTest
    static void validateForRuleWithTimeFieldAndAllOperators() {
        String fieldPath = Schema.ContactPointAddress.BestTimeToContactStartTime.getDescribe().getName();
        Time fieldValue = Time.newInstance(9, 0, 0, 0);
        ContactPointAddress record = new ContactPointAddress();
        record.put(fieldPath, fieldValue);

        Map<String, Time> operatorToValue = new Map<String, Time>{
            'EQUAL_TO' => fieldValue,
            'NOT_EQUAL_TO' => Time.newInstance(0, 0, 1, 0),
            'LESS_THAN' => Time.newInstance(23, 0, 0, 0),
            'LESS_THAN_OR_EQUAL_TO' => Time.newInstance(23, 0, 0, 0),
            'GREATER_THAN' => Time.newInstance(0, 0, 0, 10),
            'GREATER_THAN_OR_EQUAL_TO' => Time.newInstance(0, 0, 0, 10)
        };
        for (String operator : operatorToValue.keySet()) {
            Time value = operatorToValue.get(operator);

            LogEntryEventFilter__mdt rule = createMockRule();
            LogEntryEventFilterCondition__mdt condition = createMockRuleCondition(fieldPath, operator, 'Value', value);
            List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{ condition };

            RecordValidator validator = new RecordValidator(record).setRule(rule, conditions);
            List<RecordValidator.ValidationRuleResult> results = validator.validate(false);
            System.assertEquals(1, results.size(), 'Expected 1 validation rule result: ' + results);

            RecordValidator.ValidationRuleResult result = results.get(0);
            System.assertEquals(true, result.hasError, result);
            System.assertEquals(rule.ErrorMessage__c, result.errorMessage, result);

            try {
                validator.validate();
                System.assert(false, 'Exception expected on line above');
            } catch (RecordValidator.RecordValidatorException ex) {
                System.assert(ex.getMessage().contains(rule.ErrorMessage__c), ex);
            }
        }
    }

    // More complex tests
    @isTest
    static void validateForRuleWithOneBooleanFieldPathCondition() {
        Boolean managerIsActive = false;
        User manager = new User(IsActive = managerIsActive);
        User user = new User(Id = UserInfo.getUserId(), Manager = manager);

        LogEntryEventFilter__mdt rule = createMockRule();
        LogEntryEventFilterCondition__mdt condition = createMockRuleCondition('Manager.IsActive', 'EQUAL_TO', 'Value', managerIsActive);
        List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{ condition };

        RecordValidator validator = new RecordValidator(user).setRule(rule, conditions);
        List<RecordValidator.ValidationRuleResult> results = validator.validate(false);
        System.assertEquals(1, results.size(), 'Expected 1 validation rule result');

        RecordValidator.ValidationRuleResult result = results.get(0);
        System.assertEquals(true, result.hasError, result);
        System.assertEquals(rule.ErrorMessage__c, result.errorMessage, result);

        try {
            validator.validate();
            System.assert(false, 'Exception expected on line above');
        } catch (RecordValidator.RecordValidatorException ex) {
            System.assert(ex.getMessage().contains(rule.ErrorMessage__c), ex);
        }
    }

    @isTest
    static void validateForRuleWithOneRegexFieldCondition() {
        String accountName = '123';
        Account account = new Account(Name = 'Test account');
        account.Name = accountName;

        LogEntryEventFilter__mdt rule = createMockRule();
        LogEntryEventFilterCondition__mdt condition = createMockRuleCondition('Name', '^[0-9]+$', 'RegEx', accountName);
        List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{ condition };

        RecordValidator validator = new RecordValidator(account).setRule(rule, conditions);
        List<RecordValidator.ValidationRuleResult> results = validator.validate(false);
        System.assertEquals(1, results.size(), 'Expected 1 validation rule result');

        RecordValidator.ValidationRuleResult result = results.get(0);
        System.assertEquals(true, result.hasError, result);
        System.assertEquals(rule.ErrorMessage__c, result.errorMessage, result);

        try {
            validator.validate();
            System.assert(false, 'Exception expected on line above');
        } catch (RecordValidator.RecordValidatorException ex) {
            System.assert(ex.getMessage().contains(rule.ErrorMessage__c), ex);
        }
    }

    @isTest
    static void validateForRuleWithAndConditions() {
        String accountName = 'Some account';
        Integer accountAnnualRevenue = 123000;
        Account account = new Account(Name = 'Test account');
        account.Name = accountName;
        account.AnnualRevenue = accountAnnualRevenue;

        LogEntryEventFilter__mdt rule = createMockRule();
        List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{
            createMockRuleCondition('Name', 'EQUAL_TO', 'Value', accountName),
            createMockRuleCondition('AnnualRevenue', 'GREATER_THAN_OR_EQUAL_TO', 'Value', accountAnnualRevenue)
        };

        RecordValidator validator = new RecordValidator(account).setRule(rule, conditions);
        List<RecordValidator.ValidationRuleResult> results = validator.validate(false);
        System.assertEquals(1, results.size(), 'Expected 1 validation rule result');

        RecordValidator.ValidationRuleResult result = results.get(0);
        System.assertEquals(true, result.hasError, result);
        System.assertEquals(rule.ErrorMessage__c, result.errorMessage, result);

        try {
            validator.validate();
            System.assert(false, 'Exception expected on line above');
        } catch (RecordValidator.RecordValidatorException ex) {
            System.assert(ex.getMessage().contains(rule.ErrorMessage__c), ex);
        }
    }

    @isTest
    static void validateForRuleWithOrConditions() {
        String accountName1 = 'Some account';
        String accountName2 = 'another account';
        Account account = new Account(Name = 'Test account');
        account.Name = accountName1;

        LogEntryEventFilter__mdt rule = createMockRule();
        rule.ConditionLogicType__c = 'OR';
        List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{
            createMockRuleCondition('Name', 'EQUAL_TO', 'Value', accountName1),
            createMockRuleCondition('Name', 'EQUAL_TO', 'Value', accountName2)
        };

        RecordValidator validator = new RecordValidator(account).setRule(rule, conditions);
        List<RecordValidator.ValidationRuleResult> results = validator.validate(false);
        System.assertEquals(1, results.size(), 'Expected 1 validation rule result');

        RecordValidator.ValidationRuleResult result = results.get(0);
        System.assertEquals(true, result.hasError, result);
        System.assertEquals(rule.ErrorMessage__c, result.errorMessage, result);

        try {
            validator.validate();
            System.assert(false, 'Exception expected on line above');
        } catch (RecordValidator.RecordValidatorException ex) {
            System.assert(ex.getMessage().contains(rule.ErrorMessage__c), ex);
        }
    }

    @isTest
    static void validateForRuleWithCustomConditions() {
        String accountName1 = 'Some account';
        String accountName2 = 'another account';
        Integer accountAnnualRevenue = 123000;
        Account account = new Account(Name = 'Test account');
        account.Name = accountName1;
        account.AnnualRevenue = accountAnnualRevenue;

        LogEntryEventFilter__mdt rule = createMockRule();
        rule.ConditionLogicType__c = 'Custom';
        rule.CustomConditionLogic__c = '((1 OR 2) AND 3)';
        List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{
            createMockRuleCondition('Name', 'EQUAL_TO', 'Value', accountName1),
            createMockRuleCondition('Name', 'EQUAL_TO', 'Value', accountName2),
            createMockRuleCondition('AnnualRevenue', 'GREATER_THAN_OR_EQUAL_TO', 'Value', accountAnnualRevenue)
        };

        RecordValidator validator = new RecordValidator(account).setRule(rule, conditions);
        List<RecordValidator.ValidationRuleResult> results = validator.validate(false);
        System.assertEquals(1, results.size(), 'Expected 1 validation rule result');

        RecordValidator.ValidationRuleResult result = results.get(0);
        System.assertEquals(true, result.hasError, result);
        System.assertEquals(rule.ErrorMessage__c, result.errorMessage, result);

        try {
            validator.validate();
            System.assert(false, 'Exception expected on line above');
        } catch (RecordValidator.RecordValidatorException ex) {
            System.assert(ex.getMessage().contains(rule.ErrorMessage__c), ex);
        }
    } */
}
