/********************************************************************************************************
 * This file is part of the Apex Validation Rules project, released under the MIT License.              *
 * See LICENSE file or go to https://github.com/jongpie/RecordValidationRules for full license details. *
 *******************************************************************************************************/

@IsTest
private class FilteredEventLoggerPlugin_Tests {

    // Simpler tests - each test is for 1 field with a different data type
    @IsTest
    static void filterDatetimeFieldAndAllOperators() {
        String fieldPath = Schema.LogEntryEvent__e.Timestamp__c.getDescribe().getName();
        Datetime fieldValue = System.now().addDays(-3);
        LogEntryEvent__e matchingEvent = getTestLogEntryEvent();
        matchingEvent.put(fieldPath, fieldValue);

        Integer expectedPublishImmediateDml = 0;
        LogEntryEventFilter__mdt filter = createMockFilter();
        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>{ matchingEvent };
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

            LogEntryEventFilterCondition__mdt condition = createMockFilterCondition(fieldPath, operator, 'Value', value);
            List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{ condition };

            FilteredEventLoggerPlugin plugin = new FilteredEventLoggerPlugin();
            plugin.filtersByDeveloperName.put(filter.DeveloperName, filter);
            plugin.conditionsByFilterDeveloperName.put(filter.DeveloperName, conditions);

            System.assertEquals(expectedPublishImmediateDml, Limits.getPublishImmediateDml());
            plugin.execute(TriggerOperation.AFTER_INSERT, logEntryEvents, null, null, null);
            expectedPublishImmediateDml++;
            List<FilteredLogEntryEvent__e> results = plugin.filteredLogEntryEvents;
            System.assertEquals(1, results.size(), 'Expected 1 filtered log entry event: ' + results);
            System.assertEquals(expectedPublishImmediateDml, Limits.getPublishImmediateDml());
        }
    }

    @IsTest
    static void filterWithDecimalFieldAndAllOperators() {
        String fieldPath = Schema.LogEntryEvent__e.LimitsCpuTimeUsed__c.getDescribe().getName();
        Decimal fieldValue = 12345;
        LogEntryEvent__e matchingEvent = getTestLogEntryEvent();
        matchingEvent.put(fieldPath, fieldValue);

        Integer expectedPublishImmediateDml = 0;
        LogEntryEventFilter__mdt filter = createMockFilter();
        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>{ matchingEvent };
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

            LogEntryEventFilterCondition__mdt condition = createMockFilterCondition(fieldPath, operator, 'Value', value);
            List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{ condition };

            FilteredEventLoggerPlugin plugin = new FilteredEventLoggerPlugin();
            plugin.filtersByDeveloperName.put(filter.DeveloperName, filter);
            plugin.conditionsByFilterDeveloperName.put(filter.DeveloperName, conditions);

            System.assertEquals(expectedPublishImmediateDml, Limits.getPublishImmediateDml());
            plugin.execute(TriggerOperation.AFTER_INSERT, logEntryEvents, null, null, null);
            expectedPublishImmediateDml++;
            List<FilteredLogEntryEvent__e> results = plugin.filteredLogEntryEvents;
            System.assertEquals(1, results.size(), 'Expected 1 filtered log entry event: ' + results);
            System.assertEquals(expectedPublishImmediateDml, Limits.getPublishImmediateDml());
        }
    }

    @IsTest
    static void filterWithStringFieldAndAllOperators() {
        String fieldPath = Schema.LogEntryEvent__e.Message__c.getDescribe().getName();
        String fieldValue = 'Some message! Hello!';
        LogEntryEvent__e matchingEvent = getTestLogEntryEvent();
        matchingEvent.put(fieldPath, fieldValue);

        Integer expectedPublishImmediateDml = 0;
        LogEntryEventFilter__mdt filter = createMockFilter();
        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>{ matchingEvent };
        Map<String, String> operatorToValue = new Map<String, String>{
            'EQUAL_TO' => fieldValue,
            'NOT_EQUAL_TO' => 'something else',
            'STARTS_WITH' => fieldValue.left(3),
            'CONTAINS' => fieldValue.substring(2, 4),
            'ENDS_WITH' => fieldValue.right(3)
        };
        for (String operator : operatorToValue.keySet()) {
            String value = operatorToValue.get(operator);

            LogEntryEventFilterCondition__mdt condition = createMockFilterCondition(fieldPath, operator, 'Value', value);
            List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{ condition };

            FilteredEventLoggerPlugin plugin = new FilteredEventLoggerPlugin();
            plugin.filtersByDeveloperName.put(filter.DeveloperName, filter);
            plugin.conditionsByFilterDeveloperName.put(filter.DeveloperName, conditions);

            System.assertEquals(expectedPublishImmediateDml, Limits.getPublishImmediateDml());
            plugin.execute(TriggerOperation.AFTER_INSERT, logEntryEvents, null, null, null);
            expectedPublishImmediateDml++;
            List<FilteredLogEntryEvent__e> results = plugin.filteredLogEntryEvents;
            System.assertEquals(1, results.size(), 'Expected 1 filtered log entry event: ' + results);
            System.assertEquals(expectedPublishImmediateDml, Limits.getPublishImmediateDml());
        }
    }

    // More complex tests
    @IsTest
    static void filterWithOneRegexFieldCondition() {
        String matchingMessage = '123';
        String nonMatchingMessage = 'something';
        LogEntryEvent__e matchingEvent = getTestLogEntryEvent();
        matchingEvent.Message__c = matchingMessage;

        LogEntryEvent__e nonMatchingEvent = getTestLogEntryEvent();
        nonMatchingEvent.Message__c = nonMatchingMessage;

        LogEntryEventFilter__mdt filter = createMockFilter();
        LogEntryEventFilterCondition__mdt condition = createMockFilterCondition('Message__c', '^[0-9]+$', 'RegEx', matchingMessage);
        List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{ condition };

        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>{ matchingEvent, nonMatchingEvent };
        FilteredEventLoggerPlugin plugin = createAndTestPlugin(logEntryEvents, 1, filter, conditions);
        FilteredLogEntryEvent__e filteredEvent = plugin.filteredLogEntryEvents.get(0);
        System.assertEquals(matchingEvent.Message__c, filteredEvent.Message__c);
        System.assertNotEquals(nonMatchingEvent.Message__c, filteredEvent.Message__c);
    }

    @IsTest
    static void filterWithAndConditions() {
        String message = 'Some message';
        String matchingTag = '### An example tag to use for a CMDT filter condition';
        LogEntryEvent__e matchingEvent = getTestLogEntryEvent();
        matchingEvent.Message__c = message;
        matchingEvent.Tags__c = matchingEvent.Tags__c + '\n' + matchingTag;

        LogEntryEvent__e nonMatchingEvent = getTestLogEntryEvent();
        nonMatchingEvent.Message__c = message;
        System.assert(nonMatchingEvent.Tags__c.contains(matchingTag) == false, 'The non-matching event should not have the matching tag');

        LogEntryEventFilter__mdt filter = createMockFilter();
        List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{
            createMockFilterCondition('Message__c', 'EQUAL_TO', 'Value', message),
            createMockFilterCondition('Tags__c', 'CONTAINS', 'Value', matchingTag)
        };

        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>{ matchingEvent, nonMatchingEvent };
        FilteredEventLoggerPlugin plugin = createAndTestPlugin(logEntryEvents, 1, filter, conditions);
        FilteredLogEntryEvent__e filteredEvent = plugin.filteredLogEntryEvents.get(0);
        System.assertEquals(matchingEvent.Message__c, filteredEvent.Message__c);
        System.assertEquals(matchingEvent.Tags__c, filteredEvent.Tags__c);
        System.assertEquals(matchingEvent.Message__c, filteredEvent.Message__c);
        System.assertNotEquals(nonMatchingEvent.Tags__c, filteredEvent.Tags__c);
    }

    @IsTest
    static void filterWithOrConditions() {
        String message1 = 'Some message';
        String message2 = 'another message';
        LogEntryEvent__e matchingEvent = getTestLogEntryEvent();
        matchingEvent.Message__c = message1;

        LogEntryEvent__e nonMatchingEvent = getTestLogEntryEvent();
        nonMatchingEvent.Message__c = 'this message does not meet the filter conditions';
        System.assertNotEquals(message1, nonMatchingEvent.Message__c);
        System.assertNotEquals(message2, nonMatchingEvent.Message__c);

        LogEntryEventFilter__mdt filter = createMockFilter();
        filter.ConditionLogicType__c = 'OR';
        List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{
            createMockFilterCondition('Message__c', 'EQUAL_TO', 'Value', message1),
            createMockFilterCondition('Message__c', 'EQUAL_TO', 'Value', message2)
        };

        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>{ matchingEvent, nonMatchingEvent };
        FilteredEventLoggerPlugin plugin = createAndTestPlugin(logEntryEvents, 1, filter, conditions);
        FilteredLogEntryEvent__e filteredEvent = plugin.filteredLogEntryEvents.get(0);
        System.assertEquals(matchingEvent.Message__c, filteredEvent.Message__c);
        System.assertNotEquals(nonMatchingEvent.Message__c, filteredEvent.Message__c);
    }

    @IsTest
    static void validateForRuleWithCustomConditions() {
        String message1 = 'Some message';
        String message2 = 'another message';
        Integer matchingCpuTimeUsed = 123000;
        Integer nonMatchingCpuTimeUsed = 5;
        LogEntryEvent__e matchingEvent = getTestLogEntryEvent();
        matchingEvent.Message__c = message1;
        matchingEvent.LimitsCpuTimeUsed__c = matchingCpuTimeUsed;

        LogEntryEvent__e nonMatchingEvent = getTestLogEntryEvent();
        nonMatchingEvent.Message__c = message1;
        nonMatchingEvent.LimitsCpuTimeUsed__c = nonMatchingCpuTimeUsed;

        LogEntryEventFilter__mdt filter = createMockFilter();
        filter.ConditionLogicType__c = 'Custom';
        filter.CustomConditionLogic__c = '((1 OR 2) AND 3)';
        List<LogEntryEventFilterCondition__mdt> conditions = new List<LogEntryEventFilterCondition__mdt>{
            createMockFilterCondition('Message__c', 'EQUAL_TO', 'Value', message1),
            createMockFilterCondition('Message__c', 'EQUAL_TO', 'Value', message2),
            createMockFilterCondition('LimitsCpuTimeUsed__c', 'GREATER_THAN_OR_EQUAL_TO', 'Value', matchingCpuTimeUsed)
        };

        List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>{ matchingEvent, nonMatchingEvent };
        createAndTestPlugin(logEntryEvents, 1, filter, conditions);
    }

    // Helper methods
    static LogEntryEvent__e getTestLogEntryEvent() {
        List<String> tags = new List<String>{ 'a tag', 'a tag #2: another tag', 'tag #3: the final tagging', 'tag #4: now it\'s getting excessive' };
        return new LogEntryEvent__e(
            Message__c = 'Some message',
            Tags__c = String.join(tags, '\n'),
            Timestamp__c = System.now(),
            TransactionId__c = '1234'
        );
    }

    static LogEntryEventFilter__mdt createMockFilter() {
        return new LogEntryEventFilter__mdt(
            ConditionLogicType__c = 'AND',
            CustomConditionLogic__c = null,
            IsActive__c = true
        );
    }

    static LogEntryEventFilterCondition__mdt createMockFilterCondition(String fieldPath, String operator, String valueType, Object value) {
        String valueString = value instanceof String ? (String) value : JSON.serialize(value);
        return new LogEntryEventFilterCondition__mdt(
            FieldPath__c = fieldPath,
            Operator__c = operator,
            SortOrder__c = null,
            Value__c = valueString,
            ValueType__c = valueType
        );
    }

    static FilteredEventLoggerPlugin createAndTestPlugin(List<LogEntryEvent__e> logEntryEvents, Integer expectedMatches, LogEntryEventFilter__mdt filter, List<LogEntryEventFilterCondition__mdt> conditions) {
        FilteredEventLoggerPlugin plugin = new FilteredEventLoggerPlugin();
        plugin.filtersByDeveloperName.put(filter.DeveloperName, filter);
        plugin.conditionsByFilterDeveloperName.put(filter.DeveloperName, conditions);

        System.assertEquals(0, Limits.getPublishImmediateDml());
        plugin.execute(TriggerOperation.AFTER_INSERT, logEntryEvents, null, null, null);
        List<FilteredLogEntryEvent__e> results = plugin.filteredLogEntryEvents;
        System.assertEquals(expectedMatches, results.size(), 'Expected 1 filtered log entry event: ' + results);
        System.assertEquals(1, Limits.getPublishImmediateDml());

        return plugin;
    }
}
