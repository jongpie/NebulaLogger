//-----------------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                           //
// The core functionality of this plugin's code originated in https://github.com/jongpie/ApexValidationRules //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.               //
//-----------------------------------------------------------------------------------------------------------//

// TODO revise suppressed PMD rules/clean up code
@SuppressWarnings('PMD.ApexDoc, PMD.ExcessiveParameterList, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LogRetentionRulesPlugin_Tests {
    @IsTest
    static void it_should_set_retention_date_for_rule_with_one_condition_when_datetime_less_than() {
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        enablePlugin();
        Date originalLogRetentionDate = System.today().addDays(Integer.valueOf(Logger.getUserSettings().DefaultNumberOfDaysToRetainLogs__c));
        Integer numberOfDaysToRetainLogs = 90;
        Date expectedLogRetentionDate = System.today().addDays(numberOfDaysToRetainLogs);
        Datetime now = System.now();
        LogRetentionRule__mdt rule = createMockRule('rule_with_multiple_AND_conditions', 'AND', numberOfDaysToRetainLogs);
        rule.NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs;
        LogRetentionRulesPlugin.setMockRetentionRule(rule);
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Log__r.CreatedDate', 'LESS_THAN', 'Value', now)
        };
        LogRetentionRulesPlugin.setMockRetentionRuleConditions(rule, conditions);
        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        System.Test.setCreatedDate(log.Id, now.addDays(-1));
        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(originalLogRetentionDate, log.LogRetentionDate__c);

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), TransactionEntryNumber__c = 1);
        insert logEntry;

        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(expectedLogRetentionDate, log.LogRetentionDate__c);
    }

    @IsTest
    static void it_should_set_retention_date_for_rule_with_one_condition_when_datetime_less_than_or_equal_to() {
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        enablePlugin();
        Date originalLogRetentionDate = System.today().addDays(Integer.valueOf(Logger.getUserSettings().DefaultNumberOfDaysToRetainLogs__c));
        Integer numberOfDaysToRetainLogs = 90;
        Date expectedLogRetentionDate = System.today().addDays(numberOfDaysToRetainLogs);
        Datetime now = System.now();
        LogRetentionRule__mdt rule = createMockRule('rule_with_multiple_AND_conditions', 'AND', numberOfDaysToRetainLogs);
        rule.NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs;
        LogRetentionRulesPlugin.setMockRetentionRule(rule);
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Log__r.CreatedDate', 'LESS_THAN_OR_EQUAL_TO', 'Value', now)
        };
        LogRetentionRulesPlugin.setMockRetentionRuleConditions(rule, conditions);

        Log__c log = new Log__c(TransactionId__c = '1234');
        insert log;
        System.Test.setCreatedDate(log.Id, now);
        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(originalLogRetentionDate, log.LogRetentionDate__c);

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), TransactionEntryNumber__c = 1);
        insert logEntry;
        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(expectedLogRetentionDate, log.LogRetentionDate__c);
    }

    @IsTest
    static void it_should_set_retention_date_for_rule_with_one_string_equality_condition() {
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        enablePlugin();
        Date originalLogRetentionDate = System.today().addDays(Integer.valueOf(Logger.getUserSettings().DefaultNumberOfDaysToRetainLogs__c));
        Integer numberOfDaysToRetainLogs = 90;
        Date expectedLogRetentionDate = System.today().addDays(numberOfDaysToRetainLogs);
        String scenario = 'Some scenario';
        LogRetentionRule__mdt rule = createMockRule('rule_with_multiple_AND_conditions', 'AND', numberOfDaysToRetainLogs);
        rule.NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs;
        LogRetentionRulesPlugin.setMockRetentionRule(rule);
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Log__r.Scenario__c', 'EQUAL_TO', 'Value', scenario)
        };
        LogRetentionRulesPlugin.setMockRetentionRuleConditions(rule, conditions);

        Log__c log = new Log__c(Scenario__c = scenario, TransactionId__c = '1234');
        insert log;
        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(originalLogRetentionDate, log.LogRetentionDate__c);

        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), TransactionEntryNumber__c = 1);
        insert logEntry;
        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(expectedLogRetentionDate, log.LogRetentionDate__c);
    }

    @IsTest
    static void it_should_set_retention_date_for_rule_with_multiple_and_conditions() {
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        enablePlugin();
        Date originalLogRetentionDate = System.today().addDays(Integer.valueOf(Logger.getUserSettings().DefaultNumberOfDaysToRetainLogs__c));
        Integer numberOfDaysToRetainLogs = 90;
        Date expectedLogRetentionDate = System.today().addDays(numberOfDaysToRetainLogs);
        String scenario = 'Some scenario';
        Integer userLoggingLevelOrdinal = System.LoggingLevel.WARN.ordinal();
        LogRetentionRule__mdt rule = createMockRule('rule_with_multiple_AND_conditions', 'AND', numberOfDaysToRetainLogs);
        LogRetentionRulesPlugin.setMockRetentionRule(rule);
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Log__r.Scenario__c', 'EQUAL_TO', 'Value', scenario),
            createMockRuleCondition('Log__r.UserLoggingLevelOrdinal__c', 'GREATER_THAN_OR_EQUAL_TO', 'Value', userLoggingLevelOrdinal)
        };
        LogRetentionRulesPlugin.setMockRetentionRuleConditions(rule, conditions);

        Log__c log = new Log__c(Scenario__c = scenario, TransactionId__c = '1234', UserLoggingLevelOrdinal__c = userLoggingLevelOrdinal);
        insert log;
        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(originalLogRetentionDate, log.LogRetentionDate__c);
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), TransactionEntryNumber__c = 1);
        insert logEntry;

        log = [SELECT Id, LogRetentionDate__c, Scenario__c, TotalERRORLogEntries__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(expectedLogRetentionDate, log.LogRetentionDate__c, System.JSON.serializePretty(log));
    }

    @IsTest
    static void it_should_set_retention_date_for_rule_with_multiple_or_conditions() {
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        enablePlugin();
        Date originalLogRetentionDate = System.today().addDays(Integer.valueOf(Logger.getUserSettings().DefaultNumberOfDaysToRetainLogs__c));
        Integer numberOfDaysToRetainLogs = 90;
        Date expectedLogRetentionDate = System.today().addDays(numberOfDaysToRetainLogs);
        String scenario1 = 'Some scenario';
        String scenario2 = 'Another scenario';
        LogRetentionRule__mdt rule = createMockRule('rule_with_multiple_OR_conditions', 'OR', numberOfDaysToRetainLogs);
        LogRetentionRulesPlugin.setMockRetentionRule(rule);
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Log__r.Scenario__c', 'EQUAL_TO', 'Value', scenario1),
            createMockRuleCondition('Log__r.Scenario__c', 'EQUAL_TO', 'Value', scenario2)
        };
        LogRetentionRulesPlugin.setMockRetentionRuleConditions(rule, conditions);

        Log__c log = new Log__c(Scenario__c = scenario1, TransactionId__c = '1234');
        insert log;
        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(originalLogRetentionDate, log.LogRetentionDate__c);
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), TransactionEntryNumber__c = 1);
        insert logEntry;

        log = [SELECT Id, LogRetentionDate__c, Scenario__c, TotalERRORLogEntries__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(expectedLogRetentionDate, log.LogRetentionDate__c, System.JSON.serializePretty(log));
    }

    @IsTest
    static void it_should_set_retention_date_for_rule_with_multiple_custom_conditions() {
        LoggerTestConfigurator.setupMockSObjectHandlerConfigurations();
        enablePlugin();
        Date originalLogRetentionDate = System.today().addDays(Integer.valueOf(Logger.getUserSettings().DefaultNumberOfDaysToRetainLogs__c));
        Integer numberOfDaysToRetainLogs = 90;
        Date expectedLogRetentionDate = System.today().addDays(numberOfDaysToRetainLogs);
        String scenario1 = 'Some scenario';
        String scenario2 = 'Another scenario';
        Integer userLoggingLevelOrdinal = System.LoggingLevel.WARN.ordinal();
        LogRetentionRule__mdt rule = createMockRule('rule_with_multiple_OR_conditions', 'Custom', numberOfDaysToRetainLogs);
        rule.CustomConditionLogic__c = '((1 OR 2) AND 3)';
        LogRetentionRulesPlugin.setMockRetentionRule(rule);
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Log__r.Scenario__c', 'EQUAL_TO', 'Value', scenario1),
            createMockRuleCondition('Log__r.Scenario__c', 'EQUAL_TO', 'Value', scenario2),
            createMockRuleCondition('Log__r.UserLoggingLevelOrdinal__c', 'GREATER_THAN_OR_EQUAL_TO', 'Value', userLoggingLevelOrdinal)
        };
        LogRetentionRulesPlugin.setMockRetentionRuleConditions(rule, conditions);

        Log__c log = new Log__c(Scenario__c = scenario1, TransactionId__c = '1234', UserLoggingLevelOrdinal__c = userLoggingLevelOrdinal);
        insert log;
        log = [SELECT Id, LogRetentionDate__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(originalLogRetentionDate, log.LogRetentionDate__c);
        LogEntry__c logEntry = new LogEntry__c(Log__c = log.Id, LoggingLevel__c = System.LoggingLevel.ERROR.name(), TransactionEntryNumber__c = 1);
        insert logEntry;

        log = [SELECT Id, LogRetentionDate__c, Scenario__c, TotalERRORLogEntries__c FROM Log__c WHERE Id = :log.Id];
        System.Assert.areEqual(expectedLogRetentionDate, log.LogRetentionDate__c, System.JSON.serializePretty(log));
    }

    static void enablePlugin() {
        // Set the plugin's parameters
        LoggerPlugin__mdt pluginConfiguration = new LoggerPlugin__mdt(
            DeveloperName = 'LogRetentionRulesPlugin',
            IsEnabled__c = true,
            SObjectHandlerApexClass__c = LogRetentionRulesPlugin.class.getName()
        );
        LoggerTestConfigurator.setMock(pluginConfiguration);
    }

    static LogRetentionRule__mdt createMockRule(String developerName, String conditionLogicType, Integer numberOfDaysToRetainLogs) {
        return new LogRetentionRule__mdt(
            ConditionLogicType__c = conditionLogicType,
            CustomConditionLogic__c = null,
            DeveloperName = developerName,
            IsEnabled__c = true,
            NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs
        );
    }

    static LogRetentionRuleCondition__mdt createMockRuleCondition(String fieldPath, String operator, String valueType, Object value) {
        String valueString = value instanceof String ? (String) value : System.JSON.serialize(value);
        return new LogRetentionRuleCondition__mdt(
            FieldPath__c = fieldPath,
            Operator__c = operator,
            SortOrder__c = null,
            Value__c = valueString,
            ValueType__c = valueType
        );
    }
}
