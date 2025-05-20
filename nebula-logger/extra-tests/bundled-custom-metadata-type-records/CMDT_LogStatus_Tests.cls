//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Extra Tests
 * @description Integration test class used to validate that the bundled records in LoggerSObjectHandler__mdt
 *              have the expected default values.
 * @see LoggerConfigurationSelector
 * @see LogHandler
 */
@SuppressWarnings('PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class CMDT_LogStatus_Tests {
  @IsTest
  static void it_has_correct_record_for_done() {
    LogStatus__mdt bundledRecord = LogStatus__mdt.getInstance('Done');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsActive__c, 'Record should have active == true');
    System.Assert.isTrue(bundledRecord.IsClosed__c, 'Record should have closed == true');
    System.Assert.isTrue(bundledRecord.IsResolved__c, 'Record should have resolved == true');
    System.Assert.areEqual('Done', bundledRecord.Label);
  }

  @IsTest
  static void it_has_correct_record_for_ignored() {
    LogStatus__mdt bundledRecord = LogStatus__mdt.getInstance('Ignored');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsActive__c, 'Record should have active == true');
    System.Assert.isTrue(bundledRecord.IsClosed__c, 'Record should have closed == true');
    System.Assert.isFalse(bundledRecord.IsResolved__c, 'Record should have resolved == false');
    System.Assert.areEqual('Ignored', bundledRecord.Label);
  }

  @IsTest
  static void it_has_correct_record_for_in_progress() {
    LogStatus__mdt bundledRecord = LogStatus__mdt.getInstance('In_Progress');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsActive__c, 'Record should have active == true');
    System.Assert.isFalse(bundledRecord.IsClosed__c, 'Record should have closed == false');
    System.Assert.isFalse(bundledRecord.IsResolved__c, 'Record should have resolved == false');
    System.Assert.areEqual('In Progress', bundledRecord.Label);
  }

  @IsTest
  static void it_has_correct_record_for_new() {
    LogStatus__mdt bundledRecord = LogStatus__mdt.getInstance('New');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsActive__c, 'Record should have active == true');
    System.Assert.isFalse(bundledRecord.IsClosed__c, 'Record should have closed == false');
    System.Assert.isFalse(bundledRecord.IsResolved__c, 'Record should have resolved == false');
    System.Assert.areEqual('New', bundledRecord.Label);
  }

  @IsTest
  static void it_has_correct_record_for_on_hold() {
    LogStatus__mdt bundledRecord = LogStatus__mdt.getInstance('On_Hold');

    System.Assert.isNotNull(bundledRecord, 'Record is missing');
    System.Assert.isTrue(bundledRecord.IsActive__c, 'Record should have active == true');
    System.Assert.isFalse(bundledRecord.IsClosed__c, 'Record should have closed == false');
    System.Assert.isFalse(bundledRecord.IsResolved__c, 'Record should have resolved == false');
    System.Assert.areEqual('On Hold', bundledRecord.Label);
  }
}
