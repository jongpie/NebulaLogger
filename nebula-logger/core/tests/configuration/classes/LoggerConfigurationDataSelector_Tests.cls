//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class LoggerConfigurationDataSelector_Tests {
  @IsTest
  static void it_initializes_mock_lists_when_use_mocks_is_called() {
    System.Assert.isNull(LoggerConfigurationDataSelector.mockLogEntryDataMaskRules);
    System.Assert.isNull(LoggerConfigurationDataSelector.mockLogEntryTagRules);
    System.Assert.isNull(LoggerConfigurationDataSelector.mockLoggerFieldMappings);
    System.Assert.isNull(LoggerConfigurationDataSelector.mockLoggerParameters);
    System.Assert.isNull(LoggerConfigurationDataSelector.mockLoggerPlugins);
    System.Assert.isNull(LoggerConfigurationDataSelector.mockLoggerScenarioRules);
    System.Assert.isNull(LoggerConfigurationDataSelector.mockLoggerSObjectHandlers);
    System.Assert.isNull(LoggerConfigurationDataSelector.mockLogStatuses);

    LoggerConfigurationDataSelector.useMocks();

    System.Assert.areEqual(new List<LogEntryDataMaskRule__mdt>(), LoggerConfigurationDataSelector.mockLogEntryDataMaskRules);
    System.Assert.areEqual(new List<LogEntryTagRule__mdt>(), LoggerConfigurationDataSelector.mockLogEntryTagRules);
    System.Assert.areEqual(new List<LoggerFieldMapping__mdt>(), LoggerConfigurationDataSelector.mockLoggerFieldMappings);
    System.Assert.areEqual(new Map<String, LoggerParameter__mdt>(), LoggerConfigurationDataSelector.mockLoggerParameters);
    System.Assert.areEqual(new List<LoggerPlugin__mdt>(), LoggerConfigurationDataSelector.mockLoggerPlugins);
    System.Assert.areEqual(new List<LoggerScenarioRule__mdt>(), LoggerConfigurationDataSelector.mockLoggerScenarioRules);
    System.Assert.areEqual(new List<LoggerSObjectHandler__mdt>(), LoggerConfigurationDataSelector.mockLoggerSObjectHandlers);
    System.Assert.areEqual(new List<LogStatus__mdt>(), LoggerConfigurationDataSelector.mockLogStatuses);
  }

  @IsTest
  static void it_returns_log_entry_data_mask_rules_from_database() {
    List<LogEntryDataMaskRule__mdt> expectedValues = LogEntryDataMaskRule__mdt.getAll().values().deepClone();

    List<LogEntryDataMaskRule__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLogEntryDataMaskRules();

    System.Assert.areEqual(expectedValues, returnedValues);
  }

  @IsTest
  static void it_returns_log_entry_data_mask_rules_from_provided_mocks() {
    LoggerConfigurationDataSelector.mockLogEntryDataMaskRules = new List<LogEntryDataMaskRule__mdt>{
      new LogEntryDataMaskRule__mdt(DeveloperName = 'SomeDevName')
    };

    List<LogEntryDataMaskRule__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLogEntryDataMaskRules();

    System.Assert.areEqual(LoggerConfigurationDataSelector.mockLogEntryDataMaskRules, returnedValues);
  }

  @IsTest
  static void it_returns_log_entry_tag_rules_from_database() {
    List<LogEntryTagRule__mdt> expectedValues = [
      SELECT Id, SObjectField__r.QualifiedApiName, ComparisonType__c, ComparisonValue__c, Tags__c
      FROM LogEntryTagRule__mdt
      WHERE IsEnabled__c = TRUE AND SObjectType__r.DeveloperName = 'LogEntry'
    ];
    for (LogEntryTagRule__mdt rule : expectedValues) {
      rule.SObjectField__c = rule.SObjectField__r.QualifiedApiName;
    }

    List<LogEntryTagRule__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLogEntryTagRules();

    System.Assert.areEqual(expectedValues, returnedValues);
  }

  @IsTest
  static void it_returns_log_entry_tag_rules_from_provided_mocks() {
    LoggerConfigurationDataSelector.mockLogEntryTagRules = new List<LogEntryTagRule__mdt>{ new LogEntryTagRule__mdt(DeveloperName = 'SomeDevName') };

    List<LogEntryTagRule__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLogEntryTagRules();

    System.Assert.areEqual(LoggerConfigurationDataSelector.mockLogEntryTagRules, returnedValues);
  }

  @IsTest
  static void it_returns_logger_field_mappings_from_database() {
    List<LoggerFieldMapping__mdt> expectedValues = [
      SELECT
        DeveloperName,
        IsEnabled__c,
        SourceSObjectType__r.QualifiedApiName,
        SourceField__r.QualifiedApiName,
        TargetSObjectType__r.QualifiedApiName,
        TargetField__r.QualifiedApiName
      FROM LoggerFieldMapping__mdt
      WHERE IsEnabled__c = TRUE
    ];
    for (LoggerFieldMapping__mdt fieldMapping : expectedValues) {
      fieldMapping.SourceSObjectType__c = fieldMapping.SourceSObjectType__r.QualifiedApiName ?? fieldMapping.SourceSObjectType__c;
      fieldMapping.SourceField__c = fieldMapping.SourceField__r.QualifiedApiName ?? fieldMapping.SourceField__c;
      fieldMapping.TargetSObjectType__c = fieldMapping.TargetSObjectType__r.QualifiedApiName ?? fieldMapping.TargetSObjectType__c;
      fieldMapping.TargetField__c = fieldMapping.TargetField__r.QualifiedApiName ?? fieldMapping.TargetField__c;
    }

    List<LoggerFieldMapping__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerFieldMappings();

    System.Assert.areEqual(expectedValues, returnedValues);
  }

  @IsTest
  static void it_returns_logger_field_mappings_from_provided_mocks() {
    LoggerConfigurationDataSelector.mockLoggerFieldMappings = new List<LoggerFieldMapping__mdt>{ new LoggerFieldMapping__mdt(DeveloperName = 'SomeDevName') };

    List<LoggerFieldMapping__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerFieldMappings();

    System.Assert.areEqual(LoggerConfigurationDataSelector.mockLoggerFieldMappings, returnedValues);
  }

  @IsTest
  static void it_returns_logger_parameters_from_database() {
    Map<String, LoggerParameter__mdt> expectedValues = LoggerParameter__mdt.getAll().deepClone();

    Map<String, LoggerParameter__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerParameters();

    System.Assert.areEqual(expectedValues, returnedValues);
  }

  @IsTest
  static void it_returns_logger_parameters_from_provided_mocks() {
    LoggerConfigurationDataSelector.mockLoggerParameters = new Map<String, LoggerParameter__mdt>{
      'SomeDevName' => new LoggerParameter__mdt(DeveloperName = 'SomeDevName')
    };

    Map<String, LoggerParameter__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerParameters();

    System.Assert.areEqual(LoggerConfigurationDataSelector.mockLoggerParameters, returnedValues);
  }

  @IsTest
  static void it_returns_logger_plugins_from_database() {
    List<LoggerPlugin__mdt> expectedValues = LoggerPlugin__mdt.getAll().values().deepClone();

    List<LoggerPlugin__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerPlugins();

    System.Assert.areEqual(expectedValues, returnedValues);
  }

  @IsTest
  static void it_returns_logger_plugins_from_provided_mocks() {
    LoggerConfigurationDataSelector.mockLoggerPlugins = new List<LoggerPlugin__mdt>{
      new LoggerPlugin__mdt(DeveloperName = 'SomeDevName', SObjectHandlerApexClass__c = 'SomeApexClass')
    };

    List<LoggerPlugin__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerPlugins();

    System.Assert.areEqual(LoggerConfigurationDataSelector.mockLoggerPlugins, returnedValues);
  }

  @IsTest
  static void it_returns_logger_scenario_rules_from_database() {
    List<LoggerScenarioRule__mdt> expectedValues = LoggerScenarioRule__mdt.getAll().values().deepClone();

    List<LoggerScenarioRule__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerScenarioRules();

    System.Assert.areEqual(expectedValues, returnedValues);
  }

  @IsTest
  static void it_returns_logger_scenario_rules_from_provided_mocks() {
    LoggerConfigurationDataSelector.mockLoggerScenarioRules = new List<LoggerScenarioRule__mdt>{ new LoggerScenarioRule__mdt(DeveloperName = 'SomeDevName') };

    List<LoggerScenarioRule__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerScenarioRules();

    System.Assert.areEqual(LoggerConfigurationDataSelector.mockLoggerScenarioRules, returnedValues);
  }

  @IsTest
  static void it_returns_logger_sobject_handlers_from_database() {
    List<LoggerSObjectHandler__mdt> expectedValues = [
      SELECT IsEnabled__c, SObjectHandlerApexClass__c, SObjectType__r.QualifiedApiName, SObjectTypeOverride__c
      FROM LoggerSObjectHandler__mdt
      WHERE IsEnabled__c = TRUE
    ];

    List<LoggerSObjectHandler__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerSObjectHandlers();

    System.Assert.areEqual(expectedValues, returnedValues);
  }

  @IsTest
  static void it_returns_logger_sobject_handlers_from_provided_mocks() {
    LoggerConfigurationDataSelector.mockLoggerSObjectHandlers = new List<LoggerSObjectHandler__mdt>{
      new LoggerSObjectHandler__mdt(DeveloperName = 'SomeDevName')
    };

    List<LoggerSObjectHandler__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLoggerSObjectHandlers();

    System.Assert.areEqual(LoggerConfigurationDataSelector.mockLoggerSObjectHandlers, returnedValues);
  }

  @IsTest
  static void it_returns_log_statuses_from_database() {
    List<LogStatus__mdt> expectedValues = LogStatus__mdt.getAll().values().deepClone();

    List<LogStatus__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLogStatuses();

    System.Assert.areEqual(expectedValues, returnedValues);
  }

  @IsTest
  static void it_returns_log_statuses_from_provided_mocks() {
    LoggerConfigurationDataSelector.mockLogStatuses = new List<LogStatus__mdt>{ new LogStatus__mdt(DeveloperName = 'SomeDevName') };

    List<LogStatus__mdt> returnedValues = LoggerConfigurationDataSelector.getInstance().getLogStatuses();

    System.Assert.areEqual(LoggerConfigurationDataSelector.mockLogStatuses, returnedValues);
  }
}
