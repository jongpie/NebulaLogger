//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.AvoidHardcodingId, PMD.MethodNamingConventions, PMD.NcssCount')
@IsTest(IsParallel=true)
private class CallableLogger_Tests {
  // Not all orgs have OmniStudio, so not all orgs will have the OmniProcess SObject.
  // Instead of trying to create an actual ID, this test ID can be used. It was the ID
  // of an actual record in a scratch org with OmniStudio enabled.
  private static final String TEST_OMNI_PROCESS_ID = '0jNDL000000Cbac2AC';

  static {
    // Don't use the org's actual custom metadata records when running tests
    LoggerConfigurationSelector.useMocks();
    CallableLogger.returnLogEntryEventBuilderInOutput = true;
  }

  @IsTest
  static void it_returns_exception_message_for_unsupported_action_when_using_standard_approach() {
    String fakeActionName = 'some-action-that-will-never-exist-i-hope';

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call(fakeActionName, null);

    System.Assert.areEqual(4, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(false, returnedOutput.get('isSuccess'), 'Expected isSuccess == false. Output received: ' + returnedOutput);
    System.Assert.areEqual('Unknown action: ' + fakeActionName, returnedOutput.get('exceptionMessage'));
    System.Assert.isNotNull(returnedOutput.get('exceptionStackTrace'));
    System.Assert.areEqual(System.IllegalArgumentException.class.getName(), returnedOutput.get('exceptionType'));
  }

  @IsTest
  static void it_returns_exception_message_for_unsupported_action_when_using_omnistudio_approach() {
    String fakeActionName = 'some-action-that-will-never-exist-i-hope';
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call(fakeActionName, new Map<String, Object>{ 'output' => omnistudioOutput });

    System.Assert.areEqual(4, omnistudioOutput.size(), System.JSON.serializePretty(omnistudioOutput.keySet()));
    System.Assert.areEqual(false, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == false. Output received: ' + omnistudioOutput);
    System.Assert.areEqual('Unknown action: ' + fakeActionName, omnistudioOutput.get('exceptionMessage'));
    System.Assert.isNotNull(omnistudioOutput.get('exceptionStackTrace'));
    System.Assert.areEqual(System.IllegalArgumentException.class.getName(), omnistudioOutput.get('exceptionType'));
  }

  @IsTest
  static void it_requires_case_sensitive_string_values_for_action_name() {
    // The specific action being tested here (setParentLogTransactionId()) isn't really important - it could be any supported action.
    // What _is_ important is verifying that the action name is case-sensitive.
    String correctlyCasedActionName = 'getParentLogTransactionId';
    String incorrectlyCasedActionName = correctlyCasedActionName.toUpperCase();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call(incorrectlyCasedActionName, null);

    System.Assert.areEqual(4, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(false, returnedOutput.get('isSuccess'), 'Expected isSuccess == false. Output received: ' + returnedOutput);
    System.Assert.areEqual('Unknown action: ' + incorrectlyCasedActionName, returnedOutput.get('exceptionMessage'));
    System.Assert.isNotNull(returnedOutput.get('exceptionStackTrace'));
    System.Assert.areEqual(System.IllegalArgumentException.class.getName(), returnedOutput.get('exceptionType'));
  }

  @IsTest
  static void it_gets_transaction_id_when_using_standard_approach() {
    System.Assert.isNotNull(Logger.getTransactionId(), 'Test has started under the wrong conditions');

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call('getTransactionId', null);

    System.Assert.areEqual(4, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
  }

  @IsTest
  static void it_gets_transaction_id_when_using_omnistudio_approach() {
    System.Assert.isNotNull(Logger.getTransactionId(), 'Test has started under the wrong conditions');
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('getTransactionId', new Map<String, Object>{ 'output' => omnistudioOutput });

    System.Assert.areEqual(4, omnistudioOutput.size(), System.JSON.serializePretty(omnistudioOutput.keySet()));
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(Logger.getTransactionId(), omnistudioOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), omnistudioOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), omnistudioOutput.get('requestId'));
  }

  @IsTest
  static void it_gets_parent_log_transaction_id_when_using_standard_approach() {
    String mockParentLogTransactionId = 'some transaction id';
    Logger.setParentLogTransactionId(mockParentLogTransactionId);
    System.Assert.areEqual(mockParentLogTransactionId, Logger.getParentLogTransactionId(), 'Test has started under the wrong conditions');

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call('getParentLogTransactionId', null);

    System.Assert.areEqual(4, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(mockParentLogTransactionId, returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
  }

  @IsTest
  static void it_gets_parent_log_transaction_id_when_using_omnistudio_approach() {
    String mockParentLogTransactionId = 'some transaction id';
    Logger.setParentLogTransactionId(mockParentLogTransactionId);
    System.Assert.areEqual(mockParentLogTransactionId, Logger.getParentLogTransactionId(), 'Test has started under the wrong conditions');
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('getParentLogTransactionId', new Map<String, Object>{ 'output' => omnistudioOutput });

    System.Assert.areEqual(4, omnistudioOutput.size(), System.JSON.serializePretty(omnistudioOutput.keySet()));
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(Logger.getTransactionId(), omnistudioOutput.get('transactionId'));
    System.Assert.areEqual(mockParentLogTransactionId, omnistudioOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), omnistudioOutput.get('requestId'));
  }

  @IsTest
  static void it_sets_parent_log_transaction_id_when_using_standard_approach() {
    System.Assert.isNull(Logger.getParentLogTransactionId(), 'Test has started under the wrong conditions');
    String mockParentLogTransactionId = 'some transaction id';

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('setParentLogTransactionId', new Map<String, Object>{ 'parentLogTransactionId' => mockParentLogTransactionId });

    System.Assert.areEqual(4, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    System.Assert.areEqual(mockParentLogTransactionId, Logger.getParentLogTransactionId());
  }

  @IsTest
  static void it_sets_parent_log_transaction_id_when_using_omnistudio_approach() {
    System.Assert.isNull(Logger.getParentLogTransactionId(), 'Test has started under the wrong conditions');
    String mockParentLogTransactionId = 'some transaction id';
    Map<String, Object> omnistudioInput = new Map<String, Object>{ 'parentLogTransactionId' => mockParentLogTransactionId };
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('setParentLogTransactionId', new Map<String, Object>{ 'input' => omnistudioInput, 'output' => omnistudioOutput });

    System.Assert.areEqual(4, omnistudioOutput.size(), System.JSON.serializePretty(omnistudioOutput.keySet()));
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(Logger.getTransactionId(), omnistudioOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), omnistudioOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), omnistudioOutput.get('requestId'));
    System.Assert.areEqual(mockParentLogTransactionId, Logger.getParentLogTransactionId());
  }

  @IsTest
  static void it_gets_scenario_when_using_standard_approach() {
    String mockScenario = 'some scenario';
    Logger.setScenario(mockScenario);
    System.Assert.areEqual(mockScenario, Logger.getScenario(), 'Test has started under the wrong conditions');

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call('getScenario', null);

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    System.Assert.areEqual(Logger.getScenario(), returnedOutput.get('scenario'));
  }

  @IsTest
  static void it_gets_scenario_when_using_omnistudio_approach() {
    String mockScenario = 'some scenario';
    Logger.setScenario(mockScenario);
    System.Assert.areEqual(mockScenario, Logger.getScenario(), 'Test has started under the wrong conditions');
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('getScenario', new Map<String, Object>{ 'output' => omnistudioOutput });

    System.Assert.areEqual(5, omnistudioOutput.size(), System.JSON.serializePretty(omnistudioOutput.keySet()));
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(Logger.getScenario(), omnistudioOutput.get('scenario'));
    System.Assert.areEqual(Logger.getTransactionId(), omnistudioOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), omnistudioOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), omnistudioOutput.get('requestId'));
  }

  @IsTest
  static void it_sets_scenario_when_using_standard_approach() {
    System.Assert.isNull(Logger.getScenario(), 'Test has started under the wrong conditions');
    String mockScenario = 'some scenario';

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call(
      'setScenario',
      new Map<String, Object>{ 'scenario' => mockScenario }
    );

    System.Assert.areEqual(4, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    System.Assert.areEqual(mockScenario, Logger.getScenario());
  }

  @IsTest
  static void it_sets_scenario_when_using_omnistudio_approach() {
    System.Assert.isNull(Logger.getScenario(), 'Test has started under the wrong conditions');
    String mockScenario = 'some scenario';
    Map<String, Object> omnistudioInput = new Map<String, Object>{ 'scenario' => mockScenario };
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('setScenario', new Map<String, Object>{ 'input' => omnistudioInput, 'output' => omnistudioOutput });

    System.Assert.areEqual(4, omnistudioOutput.size(), System.JSON.serializePretty(omnistudioOutput.keySet()));
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(Logger.getTransactionId(), omnistudioOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), omnistudioOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), omnistudioOutput.get('requestId'));
    System.Assert.areEqual(mockScenario, Logger.getScenario());
  }

  @IsTest
  static void it_ends_scenario_when_using_standard_approach() {
    String mockScenario = 'some scenario';
    Logger.setScenario(mockScenario);
    System.Assert.areEqual(mockScenario, Logger.getScenario(), 'Test has started under the wrong conditions');

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call(
      'endScenario',
      new Map<String, Object>{ 'scenario' => mockScenario }
    );

    System.Assert.areEqual(4, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    System.Assert.isNull(Logger.getScenario());
  }

  @IsTest
  static void it_ends_scenario_when_using_omnistudio_approach() {
    String mockScenario = 'some scenario';
    Logger.setScenario(mockScenario);
    System.Assert.areEqual(mockScenario, Logger.getScenario(), 'Test has started under the wrong conditions');
    Map<String, Object> omnistudioInput = new Map<String, Object>{ 'scenario' => mockScenario };
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('endScenario', new Map<String, Object>{ 'input' => omnistudioInput, 'output' => omnistudioOutput });

    System.Assert.areEqual(4, omnistudioOutput.size(), System.JSON.serializePretty(omnistudioOutput.keySet()));
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(Logger.getTransactionId(), omnistudioOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), omnistudioOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), omnistudioOutput.get('requestId'));
    System.Assert.isNull(Logger.getScenario());
  }

  @IsTest
  static void it_adds_new_entry_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call(
      'newEntry',
      new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message }
    );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(CallableLogger_Tests.class.getName() + '.it_adds_new_entry_when_using_standard_approach', logEntryEvent.OriginLocation__c);
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_that_meets_user_logging_level_when_using_omnistudio_approach() {
    Logger.transactionQuiddity = System.Quiddity.REMOTE_ACTION;
    String loggingLevelName = System.LoggingLevel.FINE.name();
    String message = 'some log entry message';
    Map<String, Object> omnistudioInput = new Map<String, Object>{
      'loggingLevel' => loggingLevelName,
      'message' => message,
      'omniProcessId' => TEST_OMNI_PROCESS_ID
    };
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('newEntry', new Map<String, Object>{ 'input' => omnistudioInput, 'output' => omnistudioOutput });

    System.Assert.areEqual(5, omnistudioOutput.size(), System.JSON.serializePretty(omnistudioOutput.keySet()));
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(Logger.getTransactionId(), omnistudioOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), omnistudioOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), omnistudioOutput.get('requestId'));
    LogEntryEventBuilder builder = ((LogEntryEventBuilder) omnistudioOutput.get('logEntryEventBuilder'));
    System.Assert.isTrue(builder.shouldSave(), 'Expected builder.shouldSave() to return true');
    LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();
    System.Assert.areEqual(loggingLevelName, logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.isNull(logEntryEvent.OriginLocation__c, 'Expected a null for OriginLocation__c, received: ' + logEntryEvent.OriginLocation__c);
    System.Assert.areEqual(TEST_OMNI_PROCESS_ID, logEntryEvent.OriginSourceId__c);
    System.Assert.areEqual('OmniStudio', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_that_overrides_should_save_when_using_omnistudio_approach() {
    Logger.transactionQuiddity = System.Quiddity.REMOTE_ACTION;
    String userLoggingLevelName = System.LoggingLevel.WARN.name();
    Logger.getUserSettings().LoggingLevel__c = userLoggingLevelName;
    String entryLoggingLevelName = System.LoggingLevel.FINE.name();
    String message = 'some log entry message';
    Map<String, Object> omnistudioInput = new Map<String, Object>{
      'loggingLevel' => entryLoggingLevelName,
      'message' => message,
      'omniProcessId' => TEST_OMNI_PROCESS_ID,
      'shouldSave' => true
    };
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('newEntry', new Map<String, Object>{ 'input' => omnistudioInput, 'output' => omnistudioOutput });

    System.Assert.areEqual(5, omnistudioOutput.size(), System.JSON.serializePretty(omnistudioOutput.keySet()));
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(Logger.getTransactionId(), omnistudioOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), omnistudioOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), omnistudioOutput.get('requestId'));
    LogEntryEventBuilder builder = ((LogEntryEventBuilder) omnistudioOutput.get('logEntryEventBuilder'));
    System.Assert.isTrue(builder.shouldSave(), 'Expected builder.shouldSave() to return true');
    LogEntryEvent__e logEntryEvent = builder.getLogEntryEvent();
    System.Assert.areEqual(entryLoggingLevelName, logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.isNull(logEntryEvent.OriginLocation__c, 'Expected a null for OriginLocation__c, received: ' + logEntryEvent.OriginLocation__c);
    System.Assert.areEqual(TEST_OMNI_PROCESS_ID, logEntryEvent.OriginSourceId__c);
    System.Assert.areEqual('OmniStudio', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_gracefully_no_ops_new_entry_for_unmet_logging_level_when_using_omnistudio_approach() {
    Logger.transactionQuiddity = System.Quiddity.REMOTE_ACTION;
    String userLoggingLevelName = System.LoggingLevel.WARN.name();
    Logger.getUserSettings().LoggingLevel__c = userLoggingLevelName;
    String entryLoggingLevelName = System.LoggingLevel.FINE.name();
    String message = 'some log entry message';
    Map<String, Object> omnistudioInput = new Map<String, Object>{
      'loggingLevel' => entryLoggingLevelName,
      'message' => message,
      'omniProcessId' => TEST_OMNI_PROCESS_ID
    };
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('newEntry', new Map<String, Object>{ 'input' => omnistudioInput, 'output' => omnistudioOutput });

    System.Assert.areEqual(5, omnistudioOutput.size(), System.JSON.serializePretty(omnistudioOutput.keySet()));
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(Logger.getTransactionId(), omnistudioOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), omnistudioOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), omnistudioOutput.get('requestId'));
    LogEntryEventBuilder builder = ((LogEntryEventBuilder) omnistudioOutput.get('logEntryEventBuilder'));
    System.Assert.isFalse(builder.shouldSave(), 'Expected builder.shouldSave() to return false');
  }

  @IsTest
  static void it_adds_omnistudio_output_maps_to_new_entry_message_when_using_omnistudio_approach() {
    Logger.transactionQuiddity = System.Quiddity.REMOTE_ACTION;
    String loggingLevelName = System.LoggingLevel.FINE.name();
    String message = 'some log entry message';
    Map<String, Object> firstStepInput = new Map<String, Object>{ 'TextInput1' => 'Value1', 'TextInput2' => 'Value2' };
    Map<String, Object> secondStepInput = new Map<String, Object>{ 'DateInput' => System.today(), 'BooleanInput' => true };
    Map<String, Object> omnistudioInput = new Map<String, Object>{
      'loggingLevel' => loggingLevelName,
      'message' => message,
      'omniProcessId' => TEST_OMNI_PROCESS_ID,
      'someKeyForSomeString' => 'some string that should not be logged',
      'firstStepInput' => firstStepInput,
      'secondStepInput' => secondStepInput
    };
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('newEntry', new Map<String, Object>{ 'input' => omnistudioInput, 'output' => omnistudioOutput });

    System.Assert.areEqual(5, omnistudioOutput.size(), System.JSON.serializePretty(omnistudioOutput.keySet()));
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(Logger.getTransactionId(), omnistudioOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), omnistudioOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), omnistudioOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) omnistudioOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevelName, logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(
      message +
        '\n\nOmniStudio Input:\n' +
        System.JSON.serializePretty(new Map<String, Object>{ 'firstStepInput' => firstStepInput, 'secondStepInput' => secondStepInput }),
      logEntryEvent.Message__c
    );
    System.Assert.isNull(logEntryEvent.OriginLocation__c, 'Expected a null for OriginLocation__c, received: ' + logEntryEvent.OriginLocation__c);
    System.Assert.areEqual(TEST_OMNI_PROCESS_ID, logEntryEvent.OriginSourceId__c);
    System.Assert.areEqual('OmniStudio', logEntryEvent.OriginType__c);
  }

  // For the other newEntry() tests, just test the standard approach - the OmniStudio approach will use the same parameters/inputs
  @IsTest
  static void it_adds_new_entry_with_exception_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    System.Exception apexException = new System.DmlException('whoops');

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call(
      'newEntry',
      new Map<String, Object>{ 'exception' => apexException, 'loggingLevel' => loggingLevel, 'message' => message }
    );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(apexException.getMessage(), logEntryEvent.ExceptionMessage__c);
    System.Assert.areEqual(apexException.getTypeName(), logEntryEvent.ExceptionType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_exception_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_record_id_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    Id recordId = System.UserInfo.getUserId();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call(
      'newEntry',
      new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'recordId' => recordId }
    );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(recordId, logEntryEvent.RecordId__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_record_id_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_record_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    SObject record = new Schema.User(Id = System.UserInfo.getUserId());

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'record' => record });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(record), logEntryEvent.RecordJson__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_record_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_record_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    List<Schema.User> recordList = new List<Schema.User>{ new Schema.User(Id = System.UserInfo.getUserId()) };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'recordList' => recordList });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(recordList), logEntryEvent.RecordJson__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_record_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_record_map_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    Map<Id, Schema.User> recordMap = new Map<Id, Schema.User>{ System.UserInfo.getUserId() => new Schema.User(Id = System.UserInfo.getUserId()) };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'recordMap' => recordMap });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(recordMap), logEntryEvent.RecordJson__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_record_map_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_single_database_result_when_using_standard_approach() {
    Map<String, Object> resultTypeNameToDatabaseResult = new Map<String, Object>{
      Database.DeleteResult.class.getName() => LoggerMockDataCreator.createDatabaseDeleteResult(true),
      Database.EmptyRecycleBinResult.class.getName() => LoggerMockDataCreator.createDatabaseEmptyRecycleBinResult(true),
      Database.LeadConvertResult.class.getName() => LoggerMockDataCreator.createDatabaseLeadConvertResult(true),
      Database.MergeResult.class.getName() => LoggerMockDataCreator.createDatabaseMergeResult(true),
      Database.SaveResult.class.getName() => LoggerMockDataCreator.createDatabaseSaveResult(true),
      Database.UndeleteResult.class.getName() => LoggerMockDataCreator.createDatabaseUndeleteResult(true),
      // LogEntryEventBuilder appends the upsert's subtype to single results
      Database.UpsertResult.class.getName() + '.Insert' => LoggerMockDataCreator.createDatabaseUpsertResult(true, true)
    };
    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();

    for (String resultTypeName : resultTypeNameToDatabaseResult.keySet()) {
      Object databaseResult = resultTypeNameToDatabaseResult.get(resultTypeName);
      Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
        .call(
          'newEntry',
          new Map<String, Object>{ 'loggingLevel' => System.LoggingLevel.FINE, 'message' => 'some message', 'databaseResult' => databaseResult }
        );

      System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
      LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
      System.Assert.areEqual(1, logEntryEvent.DatabaseResultCollectionSize__c, resultTypeName);
      System.Assert.areEqual('Single', logEntryEvent.DatabaseResultCollectionType__c, resultTypeName);
      System.Assert.areEqual(System.JSON.serializePretty(databaseResult), logEntryEvent.DatabaseResultJson__c, resultTypeName);
      System.Assert.areEqual(resultTypeName, logEntryEvent.DatabaseResultType__c, resultTypeName);
    }
  }

  @IsTest
  static void it_adds_new_entry_with_database_result_list_when_using_standard_approach() {
    Map<String, List<Object>> resultTypeNameToDatabaseResults = new Map<String, List<Object>>{
      Database.DeleteResult.class.getName() => new List<Database.DeleteResult>{ LoggerMockDataCreator.createDatabaseDeleteResult(true) },
      Database.EmptyRecycleBinResult.class.getName() => new List<Database.EmptyRecycleBinResult>{
        LoggerMockDataCreator.createDatabaseEmptyRecycleBinResult(true)
      },
      Database.LeadConvertResult.class.getName() => new List<Database.LeadConvertResult>{ LoggerMockDataCreator.createDatabaseLeadConvertResult(true) },
      Database.MergeResult.class.getName() => new List<Database.MergeResult>{ LoggerMockDataCreator.createDatabaseMergeResult(true) },
      Database.SaveResult.class.getName() => new List<Database.SaveResult>{ LoggerMockDataCreator.createDatabaseSaveResult(true) },
      Database.UndeleteResult.class.getName() => new List<Database.UndeleteResult>{ LoggerMockDataCreator.createDatabaseUndeleteResult(true) },
      Database.UpsertResult.class.getName() => new List<Database.UpsertResult>{ LoggerMockDataCreator.createDatabaseUpsertResult(true, true) }
    };
    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();

    for (String resultTypeName : resultTypeNameToDatabaseResults.keySet()) {
      List<Object> databaseResults = resultTypeNameToDatabaseResults.get(resultTypeName);
      Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
        .call(
          'newEntry',
          new Map<String, Object>{ 'loggingLevel' => System.LoggingLevel.FINE, 'message' => 'some message', 'databaseResult' => databaseResults }
        );

      System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
      LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
      System.Assert.areEqual(databaseResults.size(), logEntryEvent.DatabaseResultCollectionSize__c, resultTypeName);
      System.Assert.areEqual('List', logEntryEvent.DatabaseResultCollectionType__c, resultTypeName);
      System.Assert.areEqual(System.JSON.serializePretty(databaseResults), logEntryEvent.DatabaseResultJson__c, resultTypeName);
      System.Assert.areEqual(resultTypeName, logEntryEvent.DatabaseResultType__c, resultTypeName);
    }
  }

  @IsTest
  static void it_returns_exception_message_for_unsupported_database_result_type_when_using_standard_approach() {
    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => System.LoggingLevel.FINE, 'message' => 'some message', 'databaseResult' => 'not a result' });

    System.Assert.areEqual(false, returnedOutput.get('isSuccess'), 'Expected isSuccess == false. Output received: ' + returnedOutput);
    System.Assert.areEqual('Unsupported type for argument databaseResult', returnedOutput.get('exceptionMessage'));
    System.Assert.areEqual(System.IllegalArgumentException.class.getName(), returnedOutput.get('exceptionType'));
  }

  @IsTest
  static void it_keeps_record_over_database_result_record_id_when_using_standard_approach() {
    Schema.User record = new Schema.User(Id = System.UserInfo.getUserId());
    Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);
    System.Assert.areNotEqual(record.Id, saveResult.getId());

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{ 'loggingLevel' => System.LoggingLevel.FINE, 'message' => 'some message', 'record' => record, 'databaseResult' => saveResult }
      );

    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(Database.SaveResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(record.Id, logEntryEvent.RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(record), logEntryEvent.RecordJson__c);
  }

  @IsTest
  static void it_ignores_unknown_arguments_for_new_entry_when_using_standard_approach() {
    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => System.LoggingLevel.FINE, 'message' => 'some message', 'someFutureArgument' => 'value' });

    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual('some message', logEntryEvent.Message__c);
  }

  @IsTest
  static void it_adds_new_entry_with_tags_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    List<String> tags = new List<String>{ 'some-tag', 'another-tag', '1' };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'tags' => tags });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    tags.sort(); // Tags are auto-sorted by LogEntryEventBuilder
    System.Assert.areEqual(String.join(tags, '\n'), logEntryEvent.Tags__c);
    System.Assert.areEqual(CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_tags_when_using_standard_approach', logEntryEvent.OriginLocation__c);
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_and_saves_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    Boolean saveLog = true;
    System.Assert.areEqual(0, Logger.getBufferSize());
    System.Assert.isNull(Logger.lastSaveMethodNameUsed);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'saveLog' => saveLog });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(0, Logger.getBufferSize());
    System.Assert.areEqual(Logger.getUserSettings().DefaultSaveMethod__c, Logger.lastSaveMethodNameUsed);
    System.Assert.areEqual(CallableLogger_Tests.class.getName() + '.it_adds_new_entry_and_saves_when_using_standard_approach', logEntryEvent.OriginLocation__c);
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_saves_log_without_specifying_a_save_method_when_using_standard_approach() {
    Logger.info('some log entry that will be saved using the default save method').getLogEntryEvent();
    System.Assert.areEqual(1, Logger.getBufferSize());
    System.Assert.isNull(Logger.lastSaveMethodNameUsed);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call('saveLog', null);

    System.Assert.areEqual(4, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    System.Assert.areEqual(0, Logger.getBufferSize());
    System.Assert.areEqual(Logger.getUserSettings().DefaultSaveMethod__c, Logger.lastSaveMethodNameUsed);
  }

  @IsTest
  static void it_saves_log_without_specifying_a_save_method_when_using_omnistudio_approach() {
    Logger.info('some log entry that will be saved using the default save method').getLogEntryEvent();
    System.Assert.areEqual(1, Logger.getBufferSize());
    System.Assert.isNull(Logger.lastSaveMethodNameUsed);
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('saveLog', new Map<String, Object>{ 'output' => omnistudioOutput });

    System.Assert.areEqual(4, omnistudioOutput.size(), omnistudioOutput.toString());
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(0, Logger.getBufferSize());
    System.Assert.areEqual(Logger.getUserSettings().DefaultSaveMethod__c, Logger.lastSaveMethodNameUsed);
  }

  @IsTest
  static void it_saves_log_with_specified_save_method_when_using_standard_approach() {
    Logger.info('some log entry that will be saved using the specified save method').getLogEntryEvent();
    System.Assert.areEqual(1, Logger.getBufferSize());
    System.Assert.isNull(Logger.lastSaveMethodNameUsed);
    String targetSaveMethodName = Logger.SaveMethod.SYNCHRONOUS_DML.name();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call(
      'saveLog',
      new Map<String, Object>{ 'saveMethodName' => targetSaveMethodName }
    );

    System.Assert.areEqual(4, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    System.Assert.areEqual(0, Logger.getBufferSize());
    System.Assert.areEqual(targetSaveMethodName, Logger.lastSaveMethodNameUsed);
  }

  @IsTest
  static void it_saves_log_with_specified_save_method_when_using_omnistudio_approach() {
    Logger.info('some log entry that will be saved using the specified save method').getLogEntryEvent();
    System.Assert.areEqual(1, Logger.getBufferSize());
    System.Assert.isNull(Logger.lastSaveMethodNameUsed);
    String targetSaveMethodName = Logger.SaveMethod.SYNCHRONOUS_DML.name();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call(
      'saveLog',
      new Map<String, Object>{ 'saveMethodName' => targetSaveMethodName }
    );

    System.Assert.areEqual(4, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    System.Assert.areEqual(0, Logger.getBufferSize());
    System.Assert.areEqual(targetSaveMethodName, Logger.lastSaveMethodNameUsed);
  }

  @IsTest
  static void it_ignores_origin_for_apex_class_names_when_using_standard_approach() {
    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();

    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('ignoreOrigin', new Map<String, Object>{ 'apexClassNames' => new List<String>{ LoggingWrapper.class.getName() } });
    LogEntryEvent__e logEntryEvent = new LoggingWrapper().newEntry(callableLoggerInstance);

    System.Assert.areEqual(4, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_ignores_origin_for_apex_class_names_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.isFalse(logEntryEvent.StackTrace__c.contains(LoggingWrapper.class.getName()), logEntryEvent.StackTrace__c);
  }

  @IsTest
  static void it_skips_missing_and_blank_apex_class_names_when_ignoring_origin_when_using_standard_approach() {
    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();

    Map<String, Object> missingNamesOutput = (Map<String, Object>) callableLoggerInstance.call('ignoreOrigin', null);
    Map<String, Object> blankNamesOutput = (Map<String, Object>) callableLoggerInstance
      .call('ignoreOrigin', new Map<String, Object>{ 'apexClassNames' => new List<String>{ null, ' ' } });
    LogEntryEvent__e logEntryEvent = new LoggingWrapper().newEntry(callableLoggerInstance);

    System.Assert.areEqual(true, missingNamesOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + missingNamesOutput);
    System.Assert.areEqual(true, blankNamesOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + blankNamesOutput);
    System.Assert.areEqual(LoggingWrapper.class.getName() + '.newEntry', logEntryEvent.OriginLocation__c);
  }

  @IsTest
  static void it_logs_try_catch_when_passed_as_action() {
    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> input = new Map<String, Object>{ 'argument_1' => 'first arg', 'argument_2' => 'second arg' };

    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call('tryCatch', input.clone());

    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual('An unexpected error occurred:\n' + System.JSON.serializePretty(input), logEntryEvent.Message__c);
    System.Assert.areEqual(System.LoggingLevel.ERROR.name(), logEntryEvent.LoggingLevel__c);
  }

  // Stands in for a calling package's logging adapter, so its stack trace line can be ignored
  private class LoggingWrapper {
    public LogEntryEvent__e newEntry(System.Callable callableLoggerInstance) {
      Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
        .call('newEntry', new Map<String, Object>{ 'loggingLevel' => System.LoggingLevel.FINE, 'message' => 'some message' });
      return ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    }
  }
}
