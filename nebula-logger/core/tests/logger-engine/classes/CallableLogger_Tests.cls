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
  static void it_adds_new_entry_with_database_delete_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    Database.DeleteResult deleteResult = LoggerMockDataCreator.createDatabaseDeleteResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResult' => deleteResult });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(1, logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(deleteResult), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.DeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_delete_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_database_empty_recycle_bin_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    Database.EmptyRecycleBinResult emptyRecycleBinResult = LoggerMockDataCreator.createDatabaseEmptyRecycleBinResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResult' => emptyRecycleBinResult });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(1, logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(emptyRecycleBinResult), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.EmptyRecycleBinResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_empty_recycle_bin_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_database_lead_convert_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    Database.LeadConvertResult leadConvertResult = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResult' => leadConvertResult });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(1, logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(leadConvertResult), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.LeadConvertResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_lead_convert_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_database_merge_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    Database.MergeResult mergeResult = LoggerMockDataCreator.createDatabaseMergeResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResult' => mergeResult });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(1, logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(mergeResult), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.MergeResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_merge_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_database_save_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResult' => saveResult });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(1, logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(saveResult), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.SaveResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_save_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_database_undelete_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    Database.UndeleteResult undeleteResult = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResult' => undeleteResult });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(1, logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(undeleteResult), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.UndeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_undelete_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_database_upsert_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    Database.UpsertResult upsertResult = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResult' => upsertResult });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(1, logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('Single', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(upsertResult), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.UpsertResult.class.getName() + '.Insert', logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_upsert_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_database_delete_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    List<Database.DeleteResult> deleteResults = new List<Database.DeleteResult>{ LoggerMockDataCreator.createDatabaseDeleteResult(true) };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResultList' => deleteResults });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(deleteResults.size(), logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(deleteResults), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.DeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_delete_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_database_empty_recycle_bin_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    List<Database.EmptyRecycleBinResult> emptyRecycleBinResults = new List<Database.EmptyRecycleBinResult>{
      LoggerMockDataCreator.createDatabaseEmptyRecycleBinResult(true)
    };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResultList' => emptyRecycleBinResults });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(emptyRecycleBinResults.size(), logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(emptyRecycleBinResults), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.EmptyRecycleBinResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_empty_recycle_bin_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_database_lead_convert_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    List<Database.LeadConvertResult> leadConvertResults = new List<Database.LeadConvertResult>{ LoggerMockDataCreator.createDatabaseLeadConvertResult(true) };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResultList' => leadConvertResults });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(leadConvertResults.size(), logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(leadConvertResults), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.LeadConvertResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_lead_convert_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_database_merge_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    List<Database.MergeResult> mergeResults = new List<Database.MergeResult>{ LoggerMockDataCreator.createDatabaseMergeResult(true) };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResultList' => mergeResults });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(mergeResults.size(), logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(mergeResults), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.MergeResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_merge_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_database_save_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ LoggerMockDataCreator.createDatabaseSaveResult(true) };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResultList' => saveResults });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(saveResults.size(), logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(saveResults), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.SaveResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_save_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_database_undelete_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    List<Database.UndeleteResult> undeleteResults = new List<Database.UndeleteResult>{ LoggerMockDataCreator.createDatabaseUndeleteResult(true) };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResultList' => undeleteResults });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(undeleteResults.size(), logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(undeleteResults), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.UndeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_undelete_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_database_upsert_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    List<Database.UpsertResult> upsertResults = new List<Database.UpsertResult>{ LoggerMockDataCreator.createDatabaseUpsertResult(true, true) };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'databaseResultList' => upsertResults });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(upsertResults.size(), logEntryEvent.DatabaseResultCollectionSize__c);
    System.Assert.areEqual('List', logEntryEvent.DatabaseResultCollectionType__c);
    System.Assert.areEqual(System.JSON.serializePretty(upsertResults), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.UpsertResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_database_upsert_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_returns_exception_message_for_list_passed_as_database_result_when_using_standard_approach() {
    List<Database.SaveResult> saveResults = new List<Database.SaveResult>{ LoggerMockDataCreator.createDatabaseSaveResult(true) };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => System.LoggingLevel.FINE, 'message' => 'some message', 'databaseResult' => saveResults });

    System.Assert.areEqual(false, returnedOutput.get('isSuccess'), 'Expected isSuccess == false. Output received: ' + returnedOutput);
    System.Assert.areEqual('Unsupported type for argument databaseResult', returnedOutput.get('exceptionMessage'));
    System.Assert.areEqual(System.IllegalArgumentException.class.getName(), returnedOutput.get('exceptionType'));
  }

  @IsTest
  static void it_returns_exception_message_for_single_result_passed_as_database_result_list_when_using_standard_approach() {
    Database.SaveResult saveResult = LoggerMockDataCreator.createDatabaseSaveResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => System.LoggingLevel.FINE, 'message' => 'some message', 'databaseResultList' => saveResult });

    System.Assert.areEqual(false, returnedOutput.get('isSuccess'), 'Expected isSuccess == false. Output received: ' + returnedOutput);
    System.Assert.areEqual(System.TypeException.class.getName(), returnedOutput.get('exceptionType'));
  }

  @IsTest
  static void it_returns_exception_message_for_unsupported_database_result_list_type_when_using_standard_approach() {
    List<String> unsupportedResults = new List<String>{ 'not a result' };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{ 'loggingLevel' => System.LoggingLevel.FINE, 'message' => 'some message', 'databaseResultList' => unsupportedResults }
      );

    System.Assert.areEqual(false, returnedOutput.get('isSuccess'), 'Expected isSuccess == false. Output received: ' + returnedOutput);
    System.Assert.areEqual('Unsupported type for argument databaseResultList', returnedOutput.get('exceptionMessage'));
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
  static void it_ignores_origin_for_apex_type_when_using_standard_approach() {
    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();

    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('ignoreOrigin', new Map<String, Object>{ 'apexType' => LoggingWrapper.class });
    LogEntryEvent__e logEntryEvent = new LoggingWrapper().newEntry(callableLoggerInstance);

    System.Assert.areEqual(4, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_ignores_origin_for_apex_type_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.isFalse(logEntryEvent.StackTrace__c.contains(LoggingWrapper.class.getName()), logEntryEvent.StackTrace__c);
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
      Map<String, Object> inputs = new Map<String, Object>{ 'loggingLevel' => System.LoggingLevel.FINE, 'message' => 'some message' };
      Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call('newEntry', inputs);
      LogEntryEventBuilder eventBuilder = (LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder');
      return eventBuilder?.getLogEntryEvent();
    }
  }
}
