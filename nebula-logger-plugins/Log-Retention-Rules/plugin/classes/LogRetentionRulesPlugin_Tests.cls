//-----------------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                           //
// The core functionality of this plugin's code originated in https://github.com/jongpie/ApexValidationRules //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.               //
//-----------------------------------------------------------------------------------------------------------//

// TODO revise suppressed PMD rules/clean up code
@SuppressWarnings(
    'PMD.ApexDoc, PMD.AvoidDebugStatements, PMD.ApexAssertionsShouldIncludeMessage, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions'
)
@IsTest
private class LogRetentionRulesPlugin_Tests {
    @IsTest
    static void it_should_set_retention_date_for_rule_with_one_condition() {
        enablePlugin();
        Date originalLogRetentionDate = System.today().addDays(Integer.valueOf(Logger.getUserSettings().DefaultNumberOfDaysToRetainLogs__c));
        Integer numberOfDaysToRetainLogs = 90;
        Date expectedLogRetentionDate = System.today().addDays(numberOfDaysToRetainLogs);
        String scenario = 'Some scenario';
        LogRetentionRule__mdt rule = createMockRule('rule_with_multiple_AND_conditions', numberOfDaysToRetainLogs);
        rule.NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs;
        LogRetentionRulesPlugin.setMockRetentionRule(rule);
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Log__r.Scenario__c', 'EQUAL_TO', 'Value', scenario)
        };
        LogRetentionRulesPlugin.setMockRetentionRuleConditions(rule, conditions);

        Log__c log = new Log__c(Scenario__c = scenario, TransactionId__c = '1234');
        insert log;
        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(originalLogRetentionDate, log.LogRetentionDate__c);

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = LoggingLevel.ERROR.name(), TransactionEntryNumber__c = 1);
        insert logEntry;
        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(expectedLogRetentionDate, log.LogRetentionDate__c);
    }

    @IsTest
    static void it_should_set_retention_date_for_rule_with_multiple_and_conditions() {
        enablePlugin();
        Date originalLogRetentionDate = System.today().addDays(Integer.valueOf(Logger.getUserSettings().DefaultNumberOfDaysToRetainLogs__c));
        Integer numberOfDaysToRetainLogs = 90;
        Date expectedLogRetentionDate = System.today().addDays(numberOfDaysToRetainLogs);
        String scenario = 'Some scenario';
        Integer numberOfERRORLogEntries = 1;
        LogRetentionRule__mdt rule = createMockRule('rule_with_multiple_AND_conditions', numberOfDaysToRetainLogs);
        LogRetentionRulesPlugin.setMockRetentionRule(rule);
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Log__r.Scenario__c', 'EQUAL_TO', 'Value', scenario),
            createMockRuleCondition('Log__r.TotalERRORLogEntries__c', 'GREATER_THAN_OR_EQUAL_TO', 'Value', numberOfERRORLogEntries)
        };
        LogRetentionRulesPlugin.setMockRetentionRuleConditions(rule, conditions);

        Log__c log = new Log__c(Scenario__c = scenario, TransactionId__c = '1234');
        insert log;
        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(originalLogRetentionDate, log.LogRetentionDate__c);

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = LoggingLevel.ERROR.name(), TransactionEntryNumber__c = 1);
        insert logEntry;
        log = [SELECT Id, LogRetentionDate__c, Scenario__c, TotalERRORLogEntries__c FROM Log__c WHERE Id = :log.Id];
        System.assertEquals(expectedLogRetentionDate, log.LogRetentionDate__c, log);
    }

    // @IsTest
    // static void validateForRuleWithOrConditions() {
    //     String accountName1 = 'Some account';
    //     String accountName2 = 'another account';
    //     Account account = new Account(Name = 'Test account');
    //     account.Name = accountName1;

    //     LogRetentionRule__mdt rule = createMockRule();
    //     rule.ConditionLogicType__c = 'OR';
    //     List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
    //         createMockRuleCondition('Name', 'EQUAL_TO', 'Value', accountName1),
    //         createMockRuleCondition('Name', 'EQUAL_TO', 'Value', accountName2)
    //     };

    //     RecordValidator validator = new RecordValidator(account).setRule(rule, conditions);
    //     List<RecordValidator.ValidationRuleResult> results = validator.validate(false);
    //     System.assertEquals(1, results.size(), 'Expected 1 validation rule result');

    //     RecordValidator.ValidationRuleResult result = results.get(0);
    //     System.assertEquals(true, result.hasError, result);
    //     System.assertEquals(rule.ErrorMessage__c, result.errorMessage, result);

    //     try {
    //         validator.validate();
    //         System.assert(false, 'Exception expected on line above');
    //     } catch (RecordValidator.RecordValidatorException ex) {
    //         System.assert(ex.getMessage().contains(rule.ErrorMessage__c), ex);
    //     }
    // }

    // @IsTest
    // static void validateForRuleWithCustomConditions() {
    //     String accountName1 = 'Some account';
    //     String accountName2 = 'another account';
    //     Integer accountAnnualRevenue = 123000;
    //     Account account = new Account(Name = 'Test account');
    //     account.Name = accountName1;
    //     account.AnnualRevenue = accountAnnualRevenue;

    //     LogRetentionRule__mdt rule = createMockRule();
    //     rule.ConditionLogicType__c = 'Custom';
    //     rule.CustomConditionLogic__c = '((1 OR 2) AND 3)';
    //     List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
    //         createMockRuleCondition('Name', 'EQUAL_TO', 'Value', accountName1),
    //         createMockRuleCondition('Name', 'EQUAL_TO', 'Value', accountName2),
    //         createMockRuleCondition('AnnualRevenue', 'GREATER_THAN_OR_EQUAL_TO', 'Value', accountAnnualRevenue)
    //     };

    //     RecordValidator validator = new RecordValidator(account).setRule(rule, conditions);
    //     List<RecordValidator.ValidationRuleResult> results = validator.validate(false);
    //     System.assertEquals(1, results.size(), 'Expected 1 validation rule result');

    //     RecordValidator.ValidationRuleResult result = results.get(0);
    //     System.assertEquals(true, result.hasError, result);
    //     System.assertEquals(rule.ErrorMessage__c, result.errorMessage, result);

    //     try {
    //         validator.validate();
    //         System.assert(false, 'Exception expected on line above');
    //     } catch (RecordValidator.RecordValidatorException ex) {
    //         System.assert(ex.getMessage().contains(rule.ErrorMessage__c), ex);
    //     }
    // }

    static void enablePlugin() {
        // Set the plugin's parameters
        LoggerPlugin__mdt slackPluginConfig = new LoggerPlugin__mdt(
            IsEnabled__c = true,
            PluginApiName__c = LogRetentionRulesPlugin.class.getName(),
            PluginType__c = 'Apex'
        );
        LoggerSObjectHandler.setMockPlugin(Schema.LogEntry__c.SObjectType, slackPluginConfig);
    }

    static LogRetentionRule__mdt createMockRule(String developerName, Integer numberOfDaysToRetainLogs) {
        return new LogRetentionRule__mdt(
            ConditionLogicType__c = 'AND',
            CustomConditionLogic__c = null,
            DeveloperName = developerName,
            IsEnabled__c = true,
            NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs
        );
    }

    static LogRetentionRuleCondition__mdt createMockRuleCondition(String fieldPath, String operator, String valueType, Object value) {
        String valueString = value instanceof String ? (String) value : JSON.serialize(value);
        return new LogRetentionRuleCondition__mdt(
            FieldPath__c = fieldPath,
            Operator__c = operator,
            SortOrder__c = null,
            Value__c = valueString,
            ValueType__c = valueType
        );
    }
}
