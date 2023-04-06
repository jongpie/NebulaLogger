//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.CyclomaticComplexity, PMD.ExcessiveParameterList, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LogRetentionFilter_Tests {
    @IsTest
    static void it_should_match_one_condition_on_datetime_equal_to() {
        Integer numberOfDaysToRetainLogs = 90;
        Datetime mockTimestamp = System.now();
        LogRetentionRule__mdt rule = createMockRule('number_equal_to');
        rule.NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs;
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Timestamp__c', 'EQUAL_TO', 'Value', mockTimestamp)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.Timestamp__c = mockTimestamp;
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.Timestamp__c = mockTimestamp.addMinutes(-9);

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_datetime_not_equal_to() {
        Integer numberOfDaysToRetainLogs = 90;
        Datetime mockTimestamp = System.now();
        LogRetentionRule__mdt rule = createMockRule('number_not_equal_to');
        rule.NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs;
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Timestamp__c', 'NOT_EQUAL_TO', 'Value', mockTimestamp)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.Timestamp__c = mockTimestamp.addMinutes(-9);
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.Timestamp__c = mockTimestamp;

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_datetime_less_than() {
        Integer numberOfDaysToRetainLogs = 90;
        Datetime mockTimestamp = System.now();
        LogRetentionRule__mdt rule = createMockRule('number_less_than');
        rule.NumberOfDaysToRetainLogs__c = numberOfDaysToRetainLogs;
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Timestamp__c', 'LESS_THAN', 'Value', mockTimestamp)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.Timestamp__c = mockTimestamp.addMinutes(-1);
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.Timestamp__c = mockTimestamp.addMinutes(+9);

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_datetime_less_than_or_equal_to() {
        Datetime mockTimestamp = System.now();
        LogRetentionRule__mdt rule = createMockRule('number_less_than_or_equal_to');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Timestamp__c', 'LESS_THAN_OR_EQUAL_TO', 'Value', mockTimestamp)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.Timestamp__c = mockTimestamp;
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.Timestamp__c = mockTimestamp.addMinutes(+9);

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_datetime_greater_than() {
        Datetime mockTimestamp = System.now();
        LogRetentionRule__mdt rule = createMockRule('number_greater_than');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Timestamp__c', 'GREATER_THAN', 'Value', mockTimestamp)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.Timestamp__c = mockTimestamp.addMinutes(+9);
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.Timestamp__c = mockTimestamp.addMinutes(-1);

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_datetime_greater_than_or_equal_to() {
        Datetime mockTimestamp = System.now();
        LogRetentionRule__mdt rule = createMockRule('number_greater_than_or_equal_to');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Timestamp__c', 'GREATER_THAN_OR_EQUAL_TO', 'Value', mockTimestamp)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.Timestamp__c = mockTimestamp;
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.Timestamp__c = mockTimestamp.addMinutes(-9);

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_throw_illegal_argument_exception_on_datetime_when_invalid_operator() {
        String invalidOperator = 'THIS_IS_AN_INVALID_OPERATOR';
        Datetime mockTimestamp = System.now();
        LogRetentionRule__mdt rule = createMockRule('number_with_invalid_operator');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Timestamp__c', invalidOperator, 'Value', mockTimestamp)
        };
        LogEntry__c mockLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType).populateRequiredFields().getRecord();
        mockLogEntry.Timestamp__c = mockTimestamp;

        System.Exception thrownIllegalArgumentException;
        try {
            new LogRetentionFilter(mockLogEntry, rule, conditions).getFilterResult();
        } catch (System.IllegalArgumentException ex) {
            thrownIllegalArgumentException = ex;
        }

        System.Assert.isNotNull(thrownIllegalArgumentException);
        System.Assert.areEqual('Unsupported operator for Datetime: ' + invalidOperator, thrownIllegalArgumentException.getMessage());
    }

    @IsTest
    static void it_should_match_one_condition_on_decimal_equal_to() {
        Integer exampleLoggingLevelOrdinal = System.LoggingLevel.INFO.ordinal();
        LogRetentionRule__mdt rule = createMockRule('number_equal_to');
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

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_decimal_not_equal_to() {
        Integer exampleLoggingLevelOrdinal = System.LoggingLevel.INFO.ordinal();
        LogRetentionRule__mdt rule = createMockRule('number_not_equal_to');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('LoggingLevelOrdinal__c', 'NOT_EQUAL_TO', 'Value', exampleLoggingLevelOrdinal)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal - 9;
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal;

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_decimal_less_than() {
        Integer exampleLoggingLevelOrdinal = System.LoggingLevel.INFO.ordinal();
        LogRetentionRule__mdt rule = createMockRule('number_less_than');
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

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_decimal_less_than_or_equal_to() {
        Integer exampleLoggingLevelOrdinal = System.LoggingLevel.INFO.ordinal();
        LogRetentionRule__mdt rule = createMockRule('number_less_than_or_equal_to');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('LoggingLevelOrdinal__c', 'LESS_THAN_OR_EQUAL_TO', 'Value', exampleLoggingLevelOrdinal)
        };
        LogEntry__c matchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        matchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal;
        LogEntry__c nonMatchingLogEntry = (LogEntry__c) LoggerMockDataCreator.createDataBuilder(Schema.LogEntry__c.SObjectType)
            .populateRequiredFields()
            .getRecord();
        nonMatchingLogEntry.LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal + 9;

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_decimal_greater_than() {
        Integer exampleLoggingLevelOrdinal = System.LoggingLevel.INFO.ordinal();
        LogRetentionRule__mdt rule = createMockRule('number_greater_than');
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

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_decimal_greater_than_or_equal_to() {
        Integer exampleLoggingLevelOrdinal = System.LoggingLevel.INFO.ordinal();
        LogRetentionRule__mdt rule = createMockRule('number_greater_than_or_equal_to');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('LoggingLevelOrdinal__c', 'GREATER_THAN_OR_EQUAL_TO', 'Value', exampleLoggingLevelOrdinal)
        };
        LogEntry__c matchingLogEntry = new LogEntry__c(LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal);
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal - 9);

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_throw_illegal_argument_exception_on_decimal_when_invalid_operator() {
        String invalidOperator = 'THIS_IS_AN_INVALID_OPERATOR';
        Integer exampleLoggingLevelOrdinal = System.LoggingLevel.INFO.ordinal();
        LogRetentionRule__mdt rule = createMockRule('number_with_invalid_operator');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('LoggingLevelOrdinal__c', invalidOperator, 'Value', exampleLoggingLevelOrdinal)
        };
        LogEntry__c mockLogEntry = new LogEntry__c(LoggingLevelOrdinal__c = exampleLoggingLevelOrdinal);

        System.Exception thrownIllegalArgumentException;
        try {
            new LogRetentionFilter(mockLogEntry, rule, conditions).getFilterResult();
        } catch (System.IllegalArgumentException ex) {
            thrownIllegalArgumentException = ex;
        }

        System.Assert.isNotNull(thrownIllegalArgumentException);
        System.Assert.areEqual('Unsupported operator for Decimal: ' + invalidOperator, thrownIllegalArgumentException.getMessage());
    }

    @IsTest
    static void it_should_match_one_condition_on_string_equal_to() {
        String mockStringValue = 'Some text';
        LogRetentionRule__mdt rule = createMockRule('string_equal_to');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Message__c', 'EQUAL_TO', 'Value', mockStringValue)
        };
        LogEntry__c matchingLogEntry = new LogEntry__c(Message__c = mockStringValue);
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(Message__c = mockStringValue + ' some extra text so it does not match');

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_string_not_equal_to() {
        String mockStringValue = 'Some text';
        LogRetentionRule__mdt rule = createMockRule('string_not_equal_to');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Message__c', 'NOT_EQUAL_TO', 'Value', mockStringValue)
        };
        LogEntry__c matchingLogEntry = new LogEntry__c(Message__c = mockStringValue + ' some extra text so it does not match');
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(Message__c = mockStringValue);

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_string_starts_with() {
        String mockStringValue = 'Some text';
        LogRetentionRule__mdt rule = createMockRule('string_starts_with');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Message__c', 'STARTS_WITH', 'Value', mockStringValue)
        };
        LogEntry__c matchingLogEntry = new LogEntry__c(Message__c = mockStringValue + ' some extra text, but this should still match using STARTS_WITH');
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(Message__c = 'This starts with something that does not match! ' + mockStringValue);

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_string_contains() {
        String mockStringValue = 'Some text';
        LogRetentionRule__mdt rule = createMockRule('string_contains');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Message__c', 'CONTAINS', 'Value', mockStringValue)
        };
        LogEntry__c matchingLogEntry = new LogEntry__c(
            Message__c = 'Some extra text at the beginning ' + mockStringValue + ' some extra text, but this should still match using STARTS_WITH'
        );
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(Message__c = 'This does not contain the matching text at all!');

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_match_one_condition_on_string_ends_with() {
        String mockStringValue = 'Some text';
        LogRetentionRule__mdt rule = createMockRule('string_ends_with', null);
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Message__c', 'ENDS_WITH', 'Value', mockStringValue)
        };
        LogEntry__c matchingLogEntry = new LogEntry__c(Message__c = 'Some extra text, but this should still match using ENDS_WITH' + mockStringValue);
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(Message__c = mockStringValue + ' and now this ends with something that does not match!');

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    @IsTest
    static void it_should_throw_illegal_argument_exception_on_string_when_invalid_operator() {
        String invalidOperator = 'THIS_IS_AN_INVALID_OPERATOR';
        String mockStringValue = 'Some text';
        LogRetentionRule__mdt rule = createMockRule('string_with_invalid_operator');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Message__c', invalidOperator, 'Value', mockStringValue)
        };
        LogEntry__c mockLogEntry = new LogEntry__c(Message__c = mockStringValue);

        System.Exception thrownIllegalArgumentException;
        try {
            new LogRetentionFilter(mockLogEntry, rule, conditions).getFilterResult();
        } catch (System.IllegalArgumentException ex) {
            thrownIllegalArgumentException = ex;
        }

        System.Assert.isNotNull(thrownIllegalArgumentException);
        System.Assert.areEqual('Unsupported operator for String: ' + invalidOperator, thrownIllegalArgumentException.getMessage());
    }

    @IsTest
    static void it_should_match_one_condition_for_parent_field() {
        String mockProfileName = 'Some profile';
        LogRetentionRule__mdt rule = createMockRule('string_equal_to');
        List<LogRetentionRuleCondition__mdt> conditions = new List<LogRetentionRuleCondition__mdt>{
            createMockRuleCondition('Log__r.ProfileName__c', 'EQUAL_TO', 'Value', mockProfileName)
        };
        LogEntry__c matchingLogEntry = new LogEntry__c(Log__r = new Log__c(ProfileName__c = mockProfileName));
        LogEntry__c nonMatchingLogEntry = new LogEntry__c(Log__r = new Log__c(ProfileName__c = 'Some other value, that should not match'));

        LogRetentionFilter.FilterResult expectedMatchResult = new LogRetentionFilter(matchingLogEntry, rule, conditions).getFilterResult();
        LogRetentionFilter.FilterResult expectedNonMatchResult = new LogRetentionFilter(nonMatchingLogEntry, rule, conditions).getFilterResult();

        System.Assert.isTrue(expectedMatchResult.matchesFilter());
        System.Assert.isFalse(expectedNonMatchResult.matchesFilter());
    }

    static LogRetentionRule__mdt createMockRule(String developerName) {
        return createMockRule(developerName, null);
    }

    static LogRetentionRule__mdt createMockRule(String developerName, String conditionLogicType) {
        return new LogRetentionRule__mdt(
            ConditionLogicType__c = conditionLogicType,
            CustomConditionLogic__c = null,
            DeveloperName = developerName,
            IsEnabled__c = true
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
