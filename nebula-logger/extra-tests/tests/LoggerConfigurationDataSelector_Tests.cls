//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerConfigurationDataSelector_Tests {
    @IsTest
    static void it_loads_mock_instance() {
        MockLoggerConfigurationDataSelector mockSelector = new MockLoggerConfigurationDataSelector();
        System.Assert.areNotEqual(mockSelector, LoggerConfigurationDataSelector.getInstance());

        LoggerConfigurationDataSelector.setMock(mockSelector);

        System.Assert.areEqual(mockSelector, LoggerConfigurationDataSelector.getInstance());
    }

    @IsTest
    static void it_returns_log_entry_data_mask_rules() {
        List<LogEntryDataMaskRule__mdt> expectedValues = LogEntryDataMaskRule__mdt.getAll().values();
        System.Assert.isFalse(expectedValues.isEmpty());

        List<LogEntryDataMaskRule__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLogEntryDataMaskRules();

        System.Assert.isFalse(returnedValues.isEmpty());
        System.Assert.areEqual(expectedValues, returnedValues);
    }

    @IsTest
    static void it_returns_log_entry_tag_rules() {
        List<LogEntryTagRule__mdt> expectedValues = LogEntryTagRule__mdt.getAll().values();
        System.Assert.isFalse(expectedValues.isEmpty());

        List<LogEntryTagRule__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLogEntryTagRules();

        System.Assert.isFalse(returnedValues.isEmpty());
        System.Assert.areEqual(expectedValues, returnedValues);
    }

    // @IsTest
    // static void it_returns_logger_field_mappings() {
    //     List<LoggerFieldMapping__mdt> expectedValues = LoggerFieldMapping__mdt.getAll().values();
    //     System.Assert.isFalse(expectedValues.isEmpty());

    //     List<LoggerFieldMapping__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerFieldMappings();

    //     System.Assert.isFalse(returnedValues.isEmpty());
    //     System.Assert.areEqual(expectedValues, returnedValues);
    // }

    @IsTest
    static void it_returns_logger_parameters() {
        List<LoggerParameter__mdt> expectedValues = LoggerParameter__mdt.getAll().values();
        System.Assert.isFalse(expectedValues.isEmpty());

        List<LoggerParameter__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerParameters();

        System.Assert.isFalse(returnedValues.isEmpty());
        System.Assert.areEqual(expectedValues, returnedValues);
    }

    @IsTest
    static void it_returns_logger_plugins() {
        List<LoggerPlugin__mdt> expectedValues = LoggerPlugin__mdt.getAll().values();
        System.Assert.isFalse(expectedValues.isEmpty());

        List<LoggerPlugin__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerPlugins();

        System.Assert.isFalse(returnedValues.isEmpty());
        System.Assert.areEqual(expectedValues, returnedValues);
    }

    @IsTest
    static void it_returns_logger_scenario_rules() {
        List<LoggerScenarioRule__mdt> expectedValues = LoggerScenarioRule__mdt.getAll().values();
        System.Assert.isFalse(expectedValues.isEmpty());

        List<LoggerScenarioRule__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerScenarioRules();

        System.Assert.isFalse(returnedValues.isEmpty());
        System.Assert.areEqual(expectedValues, returnedValues);
    }

    @IsTest
    static void it_returns_logger_sobject_handlers() {
        List<LoggerSObjectHandler__mdt> expectedValues = LoggerSObjectHandler__mdt.getAll().values();
        System.Assert.isFalse(expectedValues.isEmpty());

        List<LoggerSObjectHandler__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerSObjectHandlers();

        System.Assert.isFalse(returnedValues.isEmpty());
        System.Assert.areEqual(expectedValues, returnedValues);
    }

    @IsTest
    static void it_returns_log_statuses() {
        List<LogStatus__mdt> expectedValues = LogStatus__mdt.getAll().values();
        System.Assert.isFalse(expectedValues.isEmpty());

        List<LogStatus__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLogStatuses();

        System.Assert.isFalse(returnedValues.isEmpty());
        System.Assert.areEqual(expectedValues, returnedValues);
    }

    private class MockLoggerConfigurationDataSelector extends LoggerConfigurationDataSelector {
    }
}
