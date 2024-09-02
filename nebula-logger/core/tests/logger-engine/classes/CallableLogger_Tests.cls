//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class CallableLogger_Tests {
  @IsTest
  static void it_throws_illegal_argument_exception_for_unsupported_action() {
    String fakeActionName = 'some-action-that-will-never-exist-i-hope';
    System.IllegalArgumentException thrownException;

    try {
      new CallableLogger().call(fakeActionName, null);
    } catch (System.IllegalArgumentException ex) {
      thrownException = ex;
    }

    System.Assert.isNotNull(thrownException);
    System.Assert.areEqual('Unsupported action: ' + fakeActionName, thrownException.getMessage());
  }

  @IsTest
  static void it_gets_transaction_id() {
    System.Assert.isNotNull(Logger.getTransactionId(), 'Test has started under the wrong conditions');

    Object returnedValue = new CallableLogger().call('getTransactionId', null);

    System.Assert.areEqual(Logger.getTransactionId(), returnedValue);
  }

  @IsTest
  static void it_gets_parent_log_transaction_id() {
    String mockParentLogTransactionId = 'some transaction id';
    Logger.setParentLogTransactionId(mockParentLogTransactionId);
    System.Assert.areEqual(mockParentLogTransactionId, Logger.getParentLogTransactionId(), 'Test has started under the wrong conditions');

    Object returnedValue = new CallableLogger().call('getParentLogTransactionId', null);

    System.Assert.areEqual(mockParentLogTransactionId, returnedValue);
  }

  @IsTest
  static void it_sets_parent_log_transaction_id() {
    System.Assert.isNull(Logger.getParentLogTransactionId(), 'Test has started under the wrong conditions');
    String mockParentLogTransactionId = 'some transaction id';

    Object returnedValue = new CallableLogger()
      .call('setParentLogTransactionId', new Map<String, Object>{ 'parentLogTransactionId' => mockParentLogTransactionId });

    System.Assert.isNull(returnedValue, 'No return value expected for Logger.getParentLogTransactionId()');
    System.Assert.areEqual(mockParentLogTransactionId, Logger.getParentLogTransactionId());
  }

  @IsTest
  static void it_gets_scenario() {
    String mockScenario = 'some scenario';
    Logger.setScenario(mockScenario);
    System.Assert.areEqual(mockScenario, Logger.getScenario(), 'Test has started under the wrong conditions');

    Object returnedValue = new CallableLogger().call('getScenario', null);

    System.Assert.areEqual(mockScenario, returnedValue);
  }

  @IsTest
  static void it_sets_scenario() {
    System.Assert.fail('TODO');
  }

  @IsTest
  static void it_ends_scenario() {
    System.Assert.fail('TODO');
  }

  @IsTest
  static void it_adds_new_entry() {
    System.Assert.fail('TODO');
  }

  @IsTest
  static void it_adds_new_entry_with_exception() {
    System.Assert.fail('TODO');
  }

  @IsTest
  static void it_adds_new_entry_with_record_id() {
    System.Assert.fail('TODO');
  }

  @IsTest
  static void it_adds_new_entry_with_record() {
    System.Assert.fail('TODO');
  }

  @IsTest
  static void it_adds_new_entry_with_record_list() {
    System.Assert.fail('TODO');
  }

  @IsTest
  static void it_adds_new_entry_with_record_map() {
    System.Assert.fail('TODO');
  }

  @IsTest
  static void it_adds_new_entry_with_tags() {
    System.Assert.fail('TODO');
  }

  @IsTest
  static void it_saves_log() {
    System.Assert.fail('TODO');
  }

  @IsTest
  static void it_saves_log_with_specified_save_method() {
    System.Assert.fail('TODO');
  }
}
