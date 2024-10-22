//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Configuration
 * @description Selector class used for all queries that are specific to the configuration layer.
 *
 */
// Extra context about this class:
// All queries below are for records stored in custom metadata types (CMDT) - during Apex tests, Salesforce returns the CMDT records
// deployed to the current org when querying CMDT objects. For example:
//   - Using the CMDT object's built-in methods, like `getAll()` and `getInstance()`, will return the org's actual records during tests.
//     Docs: https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_custom_metadata_types.htm
//     `LoggerParameter__mdt.getAll();`
//     `LoggerParameter__mdt.getInstance('SomeRecordThatActuallyExistsInTheOrg');`
//   - Querying the CMDT object using SOQL has the same behavior in Apex tests: it will return the org's actual records during tests
//     `LoggerParameter__mdt someParameter = [SELECT Id FROM LoggerParameter__mdt WHERE DeveloperName = 'SomeRecordThatActuallyExistsInTheOrg'];`
// This is conceptually similar to how Salesforce returns the org's actual data when querying
// other 'setup' objects in Apex tests, such `User`, `Profile`, `Group`, etc. But this also has
// an impact on how tests need to be written when they involve any CMDT records.
//
// **For orgs using Nebula Logger**, people often (and reasonably so) want to write automated tests to validate that they're
// correctly logging data in the org - and in this context, it makes sense for Nebula Logger to query the org's actual CMDT records.
// Doing so provides a test setup where developers/admins/etc can write Apex tests that ensure that their usage of Nebula Logger works as expected,
// including any customizations that they've made using any of Nebula Logger's included CMDT objects & records. For example:
//   1. **One of Nebula Logger's `LoggerParameter__mdt` CMDT records (included out-of-the-box) has been updated to customize some behavior/feature
//      built into Nebula Logger, and developers/admins want to be able to use Apex tests to verify that logging is working in their org (including their customizations).
//         - For example, out-of-the-box, Nebula Logger has the record `QueryUserDataSynchronously`, with `Value__c` set to `true`. This results
//           in the `User` object being queried once per transaction, in any transaction that logs something. This consumes 1 SOQL query of the transaction's
//           limits for `System.Limits.getLimitQueries()` and `System.Limits.getLimitQueryRows()`. For most orgs, this is fine, but for orgs with very complex
//           codebases, they need to be able to be able to disable (`Value__c` set to `false`) - and verify that have correctly disabled - this query,
//           or any other similar query/feature built into Nebula Logger that people can customized via `LoggerParameter__mdt`.
//   2. **One of Nebula Logger's `LoggerParameter__mdt` CMDT records is misconfigured with an invalid value**. The `LoggerParameter__mdt` object
//      uses a long textarea field `Value__c` to store values to control/customize several features globally. Some of these values are
//      strings/text, but many others are Boolean values (stored as text). If these are incorrectly configured with non-Boolean values
//      (e.g., `Value__c = 'anything besides "true" or "false"`), then the associated feature in Nebula Logger may not behave the way
//      that developers/admins expect.
//   3. **Someone has created their own `LogEntryDataMaskRule__mdt` record, and they want to have a test to validate their
//      sensitive data is masked correctly.
//   4. **Someone has built their own plugin & `LoggerPlugin__mdt` record, and they want to write an Apex test to validate that their plugin is
//      correctly configured & correctly implemented (especially if there are multiple plugins being used, which could intefere with each other).
//   5. **Someone has created their own `LoggerScenario__mdt` record, and they want to write an Apex test to validate that the rule's settings
//      correctly overrides the user's `LoggerSettings__c` record.
//
//
// **But for Nebula Logger's own tests**, it shouldn't rely on the org's actual CMDT records, it needs to be able to provide mocks & test in isolation
//   to validate that different combinations of different configurations will work as expected.
//   - Plugins for Nebula Logger also need to be able to test using their own mocks. This can currently be done with some `@TestVisible` methods,
//     but that's not really ideal. Long-term, there should be a better way to do this.
//     TODO introduce a `@IsTest global` class that can be used by everyone using Nebula Logger to help with testing Nebula Logger-related functionality, including:
//       - `@IsTest global` method to provide mocks for `LoggerPlugin__mdt` records.
//       - `@IsTest global` method to provide mocks for `LoggerParameter__mdt` records.
//       - For other CMDT objects, the records in the org will be used.
//
//
// With all of that said, this class is used to:
//   - Centralize all of the CMDT queries/retrievals used by Nebula Logger's codebase (helpful for maintenance)
//   - Provide a way for Nebula Logger's tests to be run independently of the org's actual CMDT records
@SuppressWarnings('PMD.ApexCrudViolation')
public without sharing class LoggerConfigurationSelector {
  private static final LoggerConfigurationSelector INSTANCE = new LoggerConfigurationSelector();

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
  private LoggerConfigurationSelector() {
  }

  /**
   * @description The instance of `LoggerConfigurationSelector` used for any querying specific to the configuration layer
   * @return   The singleton instance of `LoggerConfigurationSelector`
   */
  public static LoggerConfigurationSelector getInstance() {
    return INSTANCE;
  }

  /**
   * @description Returns the `LogEntryDataMaskRule__mdt` records in the org.
   * @return   `List<LogEntryDataMaskRule__mdt>` containing records in the org
   */
  public List<LogEntryDataMaskRule__mdt> getLogEntryDataMaskRules() {
    return mockLogEntryDataMaskRules ?? LogEntryDataMaskRule__mdt.getAll().values().deepClone();
  }

  /**
   * @description Returns the enabled `LogEntryTagRule__mdt` records in the org, including the field `SObjectField__r.QualifiedApiName`
   *              that cannot be accessed via `LogEntryTagRule__mdt.getAll()`. The value of `SObjectField__c` is automatically
   *              set to the value of `SObjectField__r.QualifiedApiName`
   * @return   `List<LogEntryTagRule__mdt>` containing enabled records in the org
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

  /**
   * @description Returns the enabled `LoggerFieldMapping__mdt` records in the org.
   * @return   `List<LoggerFieldMapping__mdt>` containing enabled records in the org
   */
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

  /**
   * @description Returns the `LoggerParameter__mdt` records in the org.
   * @return   `List<LoggerParameter__mdt>` containing records in the org
   */
  public Map<String, LoggerParameter__mdt> getLoggerParameters() {
    return mockLoggerParameters ?? LoggerParameter__mdt.getAll().deepClone();
  }

  /**
   * @description Returns the `LoggerPlugin__mdt` records in the org.
   * @return   `List<LoggerPlugin__mdt>` containing records in the org
   */
  public List<LoggerPlugin__mdt> getLoggerPlugins() {
    return mockLoggerPlugins ?? LoggerPlugin__mdt.getAll().values().deepClone();
  }

  /**
   * @description Returns the `LoggerScenarioRule__mdt` records in the org.
   * @return   `List<LoggerScenarioRule__mdt>` containing records in the org
   */
  public List<LoggerScenarioRule__mdt> getLoggerScenarioRules() {
    return mockLoggerScenarioRules ?? LoggerScenarioRule__mdt.getAll().values().deepClone();
  }

  /**
   * @description Returns the `LoggerSObjectHandler__mdt` records in the org.
   * @return   `List<LoggerSObjectHandler__mdt>` containing records in the org
   */
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

  /**
   * @description Returns the `LogStatus__mdt` records in the org.
   * @return   `List<LogStatus__mdt>` containing records in the org
   */
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
