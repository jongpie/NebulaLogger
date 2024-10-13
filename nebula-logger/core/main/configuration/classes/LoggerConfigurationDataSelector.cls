//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Selector class used for all queries that are specific to the configuration layer
 */
public without sharing virtual class LoggerConfigurationDataSelector {
  private static final LoggerConfigurationDataSelector INSTANCE = new LoggerConfigurationDataSelector();

  @TestVisible
  private static List<LogEntryDataMaskRule__mdt> mockLogEntryDataMaskRules;
  @TestVisible
  private static List<LogEntryTagRule__mdt> mockLogEntryTagRules;
  @TestVisible
  private static List<LoggerFieldMapping__mdt> mockLoggerFieldMappings;
  @TestVisible
  private static Map<String, LoggerParameter__mdt> mockLoggerParameters;
  @TestVisible
  private static List<LoggerPlugin__mdt> mockLoggerPlugins;
  @TestVisible
  private static List<LoggerScenarioRule__mdt> mockLoggerScenarioRules;
  @TestVisible
  private static List<LoggerSObjectHandler__mdt> mockLoggerSObjectHandlers;
  @TestVisible
  private static List<LogStatus__mdt> mockLogStatuses;

  @SuppressWarnings('PMD.EmptyStatementBlock')
  @TestVisible
  private LoggerConfigurationDataSelector() {
  }

  /**
   * @description The instance `LoggerConfigurationDataSelector` used for any querying specific to the configuration layer
   * @return   The singleton instance of `LoggerConfigurationDataSelector`
   */
  public static LoggerConfigurationDataSelector getInstance() {
    return INSTANCE;
  }

  // TODO decide if LoggerSettings__c should be here (I don't think so)
  public virtual List<LogEntryDataMaskRule__mdt> getLogEntryDataMaskRules() {
    return mockLogEntryDataMaskRules ?? LogEntryDataMaskRule__mdt.getAll().values().deepClone();
  }

  /**
   * @description Returns a cached copy of the `LogEntryTagRule__mdt` records in the org,
   *              including the field `SObjectField__r.QualifiedApiName` that cannot be accessed via `LogEntryTagRule__mdt.getAll()`
   * @return   The cached `List<LogEntryTagRule__mdt>` records
   */
  public virtual List<LogEntryTagRule__mdt> getLogEntryTagRules() {
    List<LogEntryTagRule__mdt> rules = [
      SELECT Id, SObjectField__r.QualifiedApiName, ComparisonType__c, ComparisonValue__c, Tags__c
      FROM LogEntryTagRule__mdt
      WHERE IsEnabled__c = TRUE AND SObjectType__r.DeveloperName = 'LogEntry'
    ];

    if (mockLogEntryTagRules != null) {
      rules = mockLogEntryTagRules;
    }

    for (LogEntryTagRule__mdt rule : rules) {
      rule.SObjectField__c = rule.SObjectField__r.QualifiedApiName;
    }
    return rules;
  }

  public virtual List<LoggerFieldMapping__mdt> getLoggerFieldMappings() {
    return mockLoggerFieldMappings ??
      [
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
  }

  public virtual Map<String, LoggerParameter__mdt> getLoggerParameters() {
    return mockLoggerParameters ?? LoggerParameter__mdt.getAll().deepClone();
  }

  public virtual List<LoggerPlugin__mdt> getLoggerPlugins() {
    return mockLoggerPlugins ?? LoggerPlugin__mdt.getAll().values().deepClone();
  }

  public virtual List<LoggerScenarioRule__mdt> getLoggerScenarioRules() {
    return mockLoggerScenarioRules ?? LoggerScenarioRule__mdt.getAll().values().deepClone();
  }

  public virtual List<LoggerSObjectHandler__mdt> getLoggerSObjectHandlers() {
    return mockLoggerSObjectHandlers ??
      [
        SELECT IsEnabled__c, SObjectHandlerApexClass__c, SObjectType__r.QualifiedApiName, SObjectTypeOverride__c
        FROM LoggerSObjectHandler__mdt
        WHERE IsEnabled__c = TRUE
      ];
  }

  public virtual List<LogStatus__mdt> getLogStatuses() {
    return mockLogStatuses ?? LogStatus__mdt.getAll().values().deepClone();
  }

  @TestVisible
  private static void useMocks() {
    // Avoid using the org's actual custom metadata records when running tests
    // by initializing all of the mock list variables.
    // And just in case there are multiple calls made to useMocks(),
    // only set the mock variables if they're null.
    mockLogEntryDataMaskRules = mockLogEntryDataMaskRules ?? new List<LogEntryDataMaskRule__mdt>();
    mockLogEntryTagRules = mockLogEntryTagRules ?? new List<LogEntryTagRule__mdt>();
    mockLoggerFieldMappings = mockLoggerFieldMappings ?? new List<LoggerFieldMapping__mdt>();
    mockLoggerParameters = mockLoggerParameters ?? new Map<String, LoggerParameter__mdt>();
    mockLoggerPlugins = mockLoggerPlugins ?? new List<LoggerPlugin__mdt>();
    mockLoggerScenarioRules = mockLoggerScenarioRules ?? new List<LoggerScenarioRule__mdt>();
    mockLoggerSObjectHandlers = mockLoggerSObjectHandlers ?? new List<LoggerSObjectHandler__mdt>();
    mockLogStatuses = mockLogStatuses ?? new List<LogStatus__mdt>();
  }
}
