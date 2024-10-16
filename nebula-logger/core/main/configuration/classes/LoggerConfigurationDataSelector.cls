//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Selector class used for all queries that are specific to the configuration layer.
 *
 *              All queries below are for records stored in custom metadata types (CMDT) - during Apex tests,
 *              the CMDT records deployed to the current org are returned in queries. This is similar to
 *              how queries on the User object will still return the org's actual users during tests.
 *
 *              For orgs using Nebula Logger, people often (and reasonably so) want to write automated tests
 *              to validate that they're correctly logging data in the org - and in this context, it makes sense
 *              for Nebula Logger to query the org's actual CMDT records. Doing so provides a test setup where
 *              developers/admins/etc can write Apex tests that ensure their usage of Nebula Logger works as expected,
 *              while using the CMDT records/customizations deployed to their current org. For example:
 *                1. **Someone has created their own `LogEntryDataMaskRule__mdt` record, and they want to have a test to validate their
 *                   sensitive data is masked correctly.
 *                2. **Someone has built their own plugin & `LoggerPlugin__mdt` record, and they want to write an Apex test to validate that their plugin is
 *                   correctly configured & correctly implemented (especially if there are multiple plugins being used, which could intefere with each other).
 *                3. **Someone has created their own `LoggerScenario__mdt` record, and they want to write an Apex test to validate that the rule's settings
 *                   correctly overrides the user's `LoggerSettings__c` record.
 *                4. **One of Nebula Logger's `LoggerParameter__mdt` CMDT records is misconfigured with an invalid value**. The `LoggerParameter__mdt` object
 *                   uses a long textarea field `Value__c` to store values to control/customize several features globally. Some of these values are
 *                   strings/text, but many others are Boolean values (stored as text). If these are incorrectly configured with non-Boolean values
 *                   (e.g., `Value__c = 'anything besides "true" or "false"`), then the associated feature in Nebula Logger may not behave the way
 *                   that developers/admins expect.
 *
 *              But for Nebula Logger's own tests, it shouldn't rely on the org's actual CMDT records, it needs to be able to provide mocks & test in isolation
 *              to validate that different combinations of different configurations will work as expected. This class is used to:
 *                - Centralize all of the CMDT queries/retrievals used by Nebula Logger's codebase
 *                - Provide a way for Nebula Logger's tests to be run independently of the org's actual CMDT records
 */
// TODO Add Apex docs
@SuppressWarnings('PMD.ApexDoc, PMD.ApexCRUDViolation')
public without sharing class LoggerConfigurationDataSelector {
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
  public List<LogEntryDataMaskRule__mdt> getLogEntryDataMaskRules() {
    return mockLogEntryDataMaskRules ?? LogEntryDataMaskRule__mdt.getAll().values().deepClone();
  }

  /**
   * @description Returns a cached copy of the `LogEntryTagRule__mdt` records in the org,
   *              including the field `SObjectField__r.QualifiedApiName` that cannot be accessed via `LogEntryTagRule__mdt.getAll()`
   * @return   The cached `List<LogEntryTagRule__mdt>` records
   */
  public List<LogEntryTagRule__mdt> getLogEntryTagRules() {
    List<LogEntryTagRule__mdt> rules = [
      SELECT Id, SObjectField__r.QualifiedApiName, ComparisonType__c, ComparisonValue__c, Tags__c
      FROM LogEntryTagRule__mdt
      WHERE IsEnabled__c = TRUE AND SObjectType__r.DeveloperName = 'LogEntry'
    ];

    if (mockLogEntryTagRules != null) {
      rules = mockLogEntryTagRules;
    }

    for (LogEntryTagRule__mdt rule : rules) {
      rule.SObjectField__c = rule.SObjectField__r.QualifiedApiName ?? rule.SObjectField__c;
    }
    return rules;
  }

  public List<LoggerFieldMapping__mdt> getLoggerFieldMappings() {
    List<LoggerFieldMapping__mdt> fieldMappings = [
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

    if (mockLoggerFieldMappings != null) {
      fieldMappings = mockLoggerFieldMappings;
    }

    for (LoggerFieldMapping__mdt fieldMapping : fieldMappings) {
      fieldMapping.SourceSObjectType__c = fieldMapping.SourceSObjectType__r.QualifiedApiName ?? fieldMapping.SourceSObjectType__c;
      fieldMapping.SourceField__c = fieldMapping.SourceField__r.QualifiedApiName ?? fieldMapping.SourceField__c;
      fieldMapping.TargetSObjectType__c = fieldMapping.TargetSObjectType__r.QualifiedApiName ?? fieldMapping.TargetSObjectType__c;
      fieldMapping.TargetField__c = fieldMapping.TargetField__r.QualifiedApiName ?? fieldMapping.TargetField__c;
    }

    return fieldMappings;
  }

  public Map<String, LoggerParameter__mdt> getLoggerParameters() {
    return mockLoggerParameters ?? LoggerParameter__mdt.getAll().deepClone();
  }

  public List<LoggerPlugin__mdt> getLoggerPlugins() {
    return mockLoggerPlugins ?? LoggerPlugin__mdt.getAll().values().deepClone();
  }

  public List<LoggerScenarioRule__mdt> getLoggerScenarioRules() {
    return mockLoggerScenarioRules ?? LoggerScenarioRule__mdt.getAll().values().deepClone();
  }

  public List<LoggerSObjectHandler__mdt> getLoggerSObjectHandlers() {
    // TODO eventually update this method to handle mapping relationship fields to lookup fields,
    // Example: handler.SObjectType__c = handler.SObjectType__r.QualifiedApiName;
    // Right now, this is handled in LoggerSObjectHandler
    return mockLoggerSObjectHandlers ??
      [
        SELECT IsEnabled__c, SObjectHandlerApexClass__c, SObjectType__r.QualifiedApiName, SObjectTypeOverride__c
        FROM LoggerSObjectHandler__mdt
        WHERE IsEnabled__c = TRUE
      ];
  }

  public List<LogStatus__mdt> getLogStatuses() {
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
