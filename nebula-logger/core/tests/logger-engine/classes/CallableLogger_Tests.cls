//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings(
  'PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.AvoidHardcodingId, PMD.CyclomaticComplexity, PMD.MethodNamingConventions, PMD.NcssTypeCount'
)
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
  static void it_adds_new_entry_with_delete_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    Database.DeleteResult result = LoggerMockDataCreator.createDatabaseDeleteResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'result' => result, 'resultType' => Database.DeleteResult.class }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(result), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.DeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_delete_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_delete_result_and_null_type_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    Database.DeleteResult result = LoggerMockDataCreator.createDatabaseDeleteResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'result' => result });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(result), logEntryEvent.DatabaseResultJson__c);
    System.Assert.isNull(logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_delete_result_and_null_type_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_delete_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    List<Database.DeleteResult> resultList = LoggerMockDataCreator.createDatabaseDeleteResultList(15, true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'resultList' => resultList, 'resultType' => Database.DeleteResult.class }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.isNull(logEntryEvent.RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(resultList), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.DeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_delete_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_delete_result_list_and_null_type_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    List<Database.DeleteResult> resultList = LoggerMockDataCreator.createDatabaseDeleteResultList(15, true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'resultList' => resultList });

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.isNull(logEntryEvent.RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(resultList), logEntryEvent.DatabaseResultJson__c);
    System.Assert.isNull(logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_delete_result_list_and_null_type_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_empty_recycle_bin_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    Database.EmptyRecycleBinResult result = LoggerMockDataCreator.createDatabaseEmptyRecycleBinResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{
          'loggingLevel' => loggingLevel,
          'message' => message,
          'result' => result,
          'resultType' => Database.EmptyRecycleBinResult.class
        }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(result), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.EmptyRecycleBinResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_empty_recycle_bin_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_empty_recycle_bin_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    List<Database.EmptyRecycleBinResult> resultList = LoggerMockDataCreator.createDatabaseEmptyRecycleBinResultList(15, true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{
          'loggingLevel' => loggingLevel,
          'message' => message,
          'resultList' => resultList,
          'resultType' => Database.EmptyRecycleBinResult.class
        }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.isNull(logEntryEvent.RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(resultList), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.EmptyRecycleBinResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_empty_recycle_bin_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_lead_convert_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    Database.LeadConvertResult result = LoggerMockDataCreator.createDatabaseLeadConvertResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'result' => result, 'resultType' => Database.LeadConvertResult.class }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(result), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.LeadConvertResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_lead_convert_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_lead_convert_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    List<Database.LeadConvertResult> resultList = LoggerMockDataCreator.createDatabaseLeadConvertResultList(15, true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{
          'loggingLevel' => loggingLevel,
          'message' => message,
          'resultList' => resultList,
          'resultType' => Database.LeadConvertResult.class
        }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.isNull(logEntryEvent.RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(resultList), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.LeadConvertResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_lead_convert_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_merge_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    Database.MergeResult result = LoggerMockDataCreator.createDatabaseMergeResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'result' => result, 'resultType' => Database.MergeResult.class }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(result), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.MergeResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_merge_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_merge_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    List<Database.MergeResult> resultList = LoggerMockDataCreator.createDatabaseMergeResultList(15, true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'resultList' => resultList, 'resultType' => Database.MergeResult.class }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.isNull(logEntryEvent.RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(resultList), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.MergeResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_merge_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_save_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    Database.SaveResult result = LoggerMockDataCreator.createDatabaseSaveResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'result' => result, 'resultType' => Database.SaveResult.class }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(result), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.SaveResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_save_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_save_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    List<Database.SaveResult> resultList = LoggerMockDataCreator.createDatabaseSaveResultList(15, true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'resultList' => resultList, 'resultType' => Database.SaveResult.class }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.isNull(logEntryEvent.RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(resultList), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.SaveResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_save_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_undelete_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    Database.UndeleteResult result = LoggerMockDataCreator.createDatabaseUndeleteResult(true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'result' => result, 'resultType' => Database.UndeleteResult.class }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(result), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.UndeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_undelete_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_undelete_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    List<Database.UndeleteResult> resultList = LoggerMockDataCreator.createDatabaseUndeleteResultList(15, true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{
          'loggingLevel' => loggingLevel,
          'message' => message,
          'resultList' => resultList,
          'resultType' => Database.UndeleteResult.class
        }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.isNull(logEntryEvent.RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(resultList), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.UndeleteResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_undelete_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_upsert_result_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    Database.UpsertResult result = LoggerMockDataCreator.createDatabaseUpsertResult(true, true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'result' => result, 'resultType' => Database.UpsertResult.class }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(result), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.UpsertResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_upsert_result_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_upsert_result_list_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.ERROR;
    String message = 'some log entry message';
    List<Database.UpsertResult> resultList = LoggerMockDataCreator.createDatabaseUpsertResultList(15, true, true);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call(
        'newEntry',
        new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'resultList' => resultList, 'resultType' => Database.UpsertResult.class }
      );

    System.Assert.areEqual(5, returnedOutput.size(), System.JSON.serializePretty(returnedOutput.keySet()));
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
    System.Assert.areEqual(Logger.getParentLogTransactionId(), returnedOutput.get('parentLogTransactionId'));
    System.Assert.areEqual(Logger.getRequestId(), returnedOutput.get('requestId'));

    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.isNull(logEntryEvent.RecordId__c);
    System.Assert.areEqual(System.JSON.serializePretty(resultList), logEntryEvent.DatabaseResultJson__c);
    System.Assert.areEqual(Database.UpsertResult.class.getName(), logEntryEvent.DatabaseResultType__c);
    System.Assert.isNull(logEntryEvent.Tags__c);
    System.Assert.areEqual(
      CallableLogger_Tests.class.getName() + '.it_adds_new_entry_with_upsert_result_list_when_using_standard_approach',
      logEntryEvent.OriginLocation__c
    );
    System.Assert.areEqual('Apex', logEntryEvent.OriginType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_tags_when_using_standard_approach() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    List<Object> tags = new List<Object>{ 'some-tag', 'another-tag', 1 };

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
  static void it_logs_try_catch_when_passed_as_action() {
    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> input = new Map<String, Object>{ 'argument_1' => 'first arg', 'argument_2' => 'second arg' };

    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call('tryCatch', input.clone());

    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedOutput.get('logEntryEventBuilder')).getLogEntryEvent();
    System.Assert.areEqual('An unexpected error occurred:\n' + System.JSON.serializePretty(input), logEntryEvent.Message__c);
    System.Assert.areEqual(System.LoggingLevel.ERROR.name(), logEntryEvent.LoggingLevel__c);
  }
}
