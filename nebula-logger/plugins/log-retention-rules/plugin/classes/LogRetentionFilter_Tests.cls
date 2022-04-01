@IsTest
private class LogRetentionFilter_Tests {
    @IsTest
    static void it_should_match_one_condition_on_number_equal_to() {
        Date originalLogRetentionDate = System.today().addDays(Integer.valueOf(Logger.getUserSettings().DefaultNumberOfDaysToRetainLogs__c));
        Integer numberOfDaysToRetainLogs = 90;
        Date expectedLogRetentionDate = System.today().addDays(numberOfDaysToRetainLogs);
        Integer exampleLoggingLevelOrdinal = LoggingLevel.INFO.ordinal();
        LogRetentionRule__mdt rule = createMockRule('number_equal_to', null, numberOfDaysToRetainLogs);
        rule.NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs;
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('LoggingLevelOrdinal__c', 'EQUAL_TO', 'Value', exampleLoggingLevelOrdinal)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerTestMockCreator.createDataGenerator(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal;
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerTestMockCreator.createDataGenerator(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal - 9;

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.assertEquals(true, expectedMatchResult.matchesFilter);
        System.assertEquals(false, expectedNonMatchResult.matchesFilter);
    }

    @IsTest
    static void it_should_match_one_condition_on_number_greater_than() {
        Date originalLogRetentionDate = System.today().addDays(Integer.valueOf(Logger.getUserSettings().DefaultNumberOfDaysToRetainLogs__c));
        Integer numberOfDaysToRetainLogs = 90;
        Date expectedLogRetentionDate = System.today().addDays(numberOfDaysToRetainLogs);
        Integer exampleLoggingLevelOrdinal = LoggingLevel.INFO.ordinal();
        LogRetentionRule__mdt rule = createMockRule('number_greater_than', null, numberOfDaysToRetainLogs);
        rule.NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs;
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('LoggingLevelOrdinal__c', 'GREATER_THAN', 'Value', exampleLoggingLevelOrdinal)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerTestMockCreator.createDataGenerator(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal + 9;
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerTestMockCreator.createDataGenerator(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal - 1;

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.assertEquals(true, expectedMatchResult.matchesFilter);
        System.assertEquals(false, expectedNonMatchResult.matchesFilter);
    }

    @IsTest
    static void it_should_match_one_condition_on_number_less_than() {
        Date originalLogRetentionDate = System.today().addDays(Integer.valueOf(Logger.getUserSettings().DefaultNumberOfDaysToRetainLogs__c));
        Integer numberOfDaysToRetainLogs = 90;
        Date expectedLogRetentionDate = System.today().addDays(numberOfDaysToRetainLogs);
        Integer exampleLoggingLevelOrdinal = LoggingLevel.INFO.ordinal();
        LogRetentionRule__mdt rule = createMockRule('number_less_than', null, numberOfDaysToRetainLogs);
        rule.NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs;
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('LoggingLevelOrdinal__c', 'LESS_THAN', 'Value', exampleLoggingLevelOrdinal)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerTestMockCreator.createDataGenerator(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal - 1;
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerTestMockCreator.createDataGenerator(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal + 9;

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.assertEquals(true, expectedMatchResult.matchesFilter);
        System.assertEquals(false, expectedNonMatchResult.matchesFilter);
    }

    @IsTest
    static void it_should_have_tests() {
        System.assert(false, 'TODO');
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
