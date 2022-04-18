//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LogRetentionFilter_Tests {
    @IsTest
    static void it_should_match_one_condition_on_number_equal_to() {
        Integer numberOfDaysToRetainLogs = 90;
        Integer exampleLoggingLevelOrdinal = LoggingLevel.INFO.ordinal();
        LogRetentionRule__mdt rule = createMockRule('number_equal_to', null, numberOfDaysToRetainLogs);
        rule.NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs;
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('LoggingLevelOrdinal__c', 'EQUAL_TO', 'Value', exampleLoggingLevelOrdinal)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal;
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal - 9;

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.assertEquals(true, expectedMatchResult.matchesFilter());
        System.assertEquals(false, expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_number_greater_than() {
        Integer numberOfDaysToRetainLogs = 90;
        Integer exampleLoggingLevelOrdinal = LoggingLevel.INFO.ordinal();
        LogRetentionRule__mdt rule = createMockRule('number_greater_than', null, numberOfDaysToRetainLogs);
        rule.NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs;
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('LoggingLevelOrdinal__c', 'GREATER_THAN', 'Value', exampleLoggingLevelOrdinal)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal + 9;
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal - 1;

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.assertEquals(true, expectedMatchResult.matchesFilter());
        System.assertEquals(false, expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_number_less_than() {
        Integer numberOfDaysToRetainLogs = 90;
        Integer exampleLoggingLevelOrdinal = LoggingLevel.INFO.ordinal();
        LogRetentionRule__mdt rule = createMockRule('number_less_than', null, numberOfDaysToRetainLogs);
        rule.NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs;
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('LoggingLevelOrdinal__c', 'LESS_THAN', 'Value', exampleLoggingLevelOrdinal)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal - 1;
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal + 9;

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.assertEquals(true, expectedMatchResult.matchesFilter());
        System.assertEquals(false, expectedNonMatchResult.matchesFilter());
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
