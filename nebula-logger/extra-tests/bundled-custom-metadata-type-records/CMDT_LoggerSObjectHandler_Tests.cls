//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Extra Tests
 * @description Integration test class used to validate that the bundled records in LoggerSObjectHandler__mdt
 *              have the expected default values.
 * @see LoggerConfigurationSelector
 * @see LoggerSObjectHandler
 */
@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class CMDT_LoggerSObjectHandler_Tests {
  @IsTest
  static void it_has_correct_record_for_log_entry_event() {
    LoggerSObjectHandler__mdt bundledRecord = LoggerSObjectHandler__mdt.getInstance('LogEntryEventHandler');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'Record should be enabled');
    System.Assert.areEqual('LogEntryEventHandler config', bundledRecord.Label);
    System.Assert.areEqual(LogEntryEventHandler.class.getName(), bundledRecord.SObjectHandlerApexClass__c);
    System.Assert.isNull(bundledRecord.SObjectTypeOverride__c, 'SObject Type Override should be null');
    // Relationship fields have to be queried, so query the CMDT record to get it
    String configuredSObjectApiName = [SELECT SObjectType__r.QualifiedApiName FROM LoggerSObjectHandler__mdt WHERE DeveloperName = :bundledRecord.DeveloperName]
    .SObjectType__r.QualifiedApiName;
    System.Assert.areEqual(LogEntryEvent__e.SObjectType.getDescribe().getLocalName(), configuredSObjectApiName);
  }

  @IsTest
  static void it_has_correct_record_for_log_entry_tag() {
    LoggerSObjectHandler__mdt bundledRecord = LoggerSObjectHandler__mdt.getInstance('LogEntryTagHandler');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'Record should be enabled');
    System.Assert.areEqual('LogEntryTagHandler config', bundledRecord.Label);
    System.Assert.areEqual(LogEntryTagHandler.class.getName(), bundledRecord.SObjectHandlerApexClass__c);
    System.Assert.isNull(bundledRecord.SObjectTypeOverride__c, 'SObject Type Override should be null');
    // Relationship fields have to be queried, so query the CMDT record to get it
    String configuredSObjectApiName = [SELECT SObjectType__r.QualifiedApiName FROM LoggerSObjectHandler__mdt WHERE DeveloperName = :bundledRecord.DeveloperName]
    .SObjectType__r.QualifiedApiName;
    System.Assert.areEqual(LogEntryTag__c.SObjectType.getDescribe().getLocalName(), configuredSObjectApiName);
  }

  @IsTest
  static void it_has_correct_record_for_log_entry() {
    LoggerSObjectHandler__mdt bundledRecord = LoggerSObjectHandler__mdt.getInstance('LogEntryHandler');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'Record should be enabled');
    System.Assert.areEqual('LogEntryHandler config', bundledRecord.Label);
    System.Assert.areEqual(LogEntryHandler.class.getName(), bundledRecord.SObjectHandlerApexClass__c);
    System.Assert.isNull(bundledRecord.SObjectTypeOverride__c, 'SObject Type Override should be null');
    // Relationship fields have to be queried, so query the CMDT record to get it
    String configuredSObjectApiName = [SELECT SObjectType__r.QualifiedApiName FROM LoggerSObjectHandler__mdt WHERE DeveloperName = :bundledRecord.DeveloperName]
    .SObjectType__r.QualifiedApiName;
    System.Assert.areEqual(LogEntry__c.SObjectType.getDescribe().getLocalName(), configuredSObjectApiName);
  }

  @IsTest
  static void it_has_correct_record_for_log() {
    LoggerSObjectHandler__mdt bundledRecord = LoggerSObjectHandler__mdt.getInstance('LogHandler');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'Record should be enabled');
    System.Assert.areEqual('LogHandler config', bundledRecord.Label);
    System.Assert.areEqual(LogHandler.class.getName(), bundledRecord.SObjectHandlerApexClass__c);
    System.Assert.isNull(bundledRecord.SObjectTypeOverride__c, 'SObject Type Override should be null');
    // Relationship fields have to be queried, so query the CMDT record to get it
    String configuredSObjectApiName = [SELECT SObjectType__r.QualifiedApiName FROM LoggerSObjectHandler__mdt WHERE DeveloperName = :bundledRecord.DeveloperName]
    .SObjectType__r.QualifiedApiName;
    System.Assert.areEqual(Log__c.SObjectType.getDescribe().getLocalName(), configuredSObjectApiName);
  }

  @IsTest
  static void it_has_correct_record_for_logger_scenario() {
    LoggerSObjectHandler__mdt bundledRecord = LoggerSObjectHandler__mdt.getInstance('LoggerScenarioHandler');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'Record should be enabled');
    System.Assert.areEqual('LoggerScenarioHandler config', bundledRecord.Label);
    System.Assert.areEqual(LoggerScenarioHandler.class.getName(), bundledRecord.SObjectHandlerApexClass__c);
    System.Assert.isNull(bundledRecord.SObjectTypeOverride__c, 'SObject Type Override should be null');
    // Relationship fields have to be queried, so query the CMDT record to get it
    String configuredSObjectApiName = [SELECT SObjectType__r.QualifiedApiName FROM LoggerSObjectHandler__mdt WHERE DeveloperName = :bundledRecord.DeveloperName]
    .SObjectType__r.QualifiedApiName;
    System.Assert.areEqual(LoggerScenario__c.SObjectType.getDescribe().getLocalName(), configuredSObjectApiName);
  }

  @IsTest
  static void it_has_correct_record_for_logger_tag() {
    LoggerSObjectHandler__mdt bundledRecord = LoggerSObjectHandler__mdt.getInstance('LoggerTagHandler');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsEnabled__c, 'Record should be enabled');
    System.Assert.areEqual('LoggerTagHandler config', bundledRecord.Label);
    System.Assert.areEqual(LoggerTagHandler.class.getName(), bundledRecord.SObjectHandlerApexClass__c);
    System.Assert.isNull(bundledRecord.SObjectTypeOverride__c, 'SObject Type Override should be null');
    // Relationship fields have to be queried, so query the CMDT record to get it
    String configuredSObjectApiName = [SELECT SObjectType__r.QualifiedApiName FROM LoggerSObjectHandler__mdt WHERE DeveloperName = :bundledRecord.DeveloperName]
    .SObjectType__r.QualifiedApiName;
    System.Assert.areEqual(LoggerTag__c.SObjectType.getDescribe().getLocalName(), configuredSObjectApiName);
  }
}
