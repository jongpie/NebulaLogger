//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.ApexAssertionsShouldIncludeMessage, PMD.MethodNamingConventions')
@IsTest(IsParallel=true)
private class CallableLogger_Tests {
  @IsTest
  static void it_returns_error_message_for_unsupported_action_when_using_standard_approach() {
    String fakeActionName = 'some-action-that-will-never-exist-i-hope';

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call(fakeActionName, null);

    System.Assert.areEqual(2, returnedOutput.size());
    System.Assert.areEqual(false, returnedOutput.get('isSuccess'), 'Expected isSuccess == false. Output received: ' + returnedOutput);
    System.Assert.areEqual('Unsupported action: ' + fakeActionName, returnedOutput.get('errorMessage'));
  }

  @IsTest
  static void it_returns_error_message_for_unsupported_action_when_using_omnistudio_approach() {
    String fakeActionName = 'some-action-that-will-never-exist-i-hope';
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call(fakeActionName, new Map<String, Object>{ 'output' => omnistudioOutput });

    System.Assert.areEqual(2, omnistudioOutput.size());
    System.Assert.areEqual(false, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == false. Output received: ' + omnistudioOutput);
    System.Assert.areEqual('Unsupported action: ' + fakeActionName, omnistudioOutput.get('errorMessage'));
  }

  @IsTest
  static void it_gets_transaction_id_when_using_standard_approach() {
    System.Assert.isNotNull(Logger.getTransactionId(), 'Test has started under the wrong conditions');

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call('getTransactionId', null);

    System.Assert.areEqual(2, returnedOutput.size());
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(Logger.getTransactionId(), returnedOutput.get('transactionId'));
  }

  @IsTest
  static void it_gets_transaction_id_when_using_omnistudio_approach() {
    System.Assert.isNotNull(Logger.getTransactionId(), 'Test has started under the wrong conditions');
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('getTransactionId', new Map<String, Object>{ 'output' => omnistudioOutput });

    System.Assert.areEqual(2, omnistudioOutput.size());
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(Logger.getTransactionId(), omnistudioOutput.get('transactionId'));
  }

  @IsTest
  static void it_gets_parent_log_transaction_id_when_using_standard_approach() {
    String mockParentLogTransactionId = 'some transaction id';
    Logger.setParentLogTransactionId(mockParentLogTransactionId);
    System.Assert.areEqual(mockParentLogTransactionId, Logger.getParentLogTransactionId(), 'Test has started under the wrong conditions');

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call('getParentLogTransactionId', null);

    System.Assert.areEqual(2, returnedOutput.size());
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(mockParentLogTransactionId, returnedOutput.get('parentLogTransactionId'));
  }

  @IsTest
  static void it_gets_parent_log_transaction_id_when_using_omnistudio_approach() {
    String mockParentLogTransactionId = 'some transaction id';
    Logger.setParentLogTransactionId(mockParentLogTransactionId);
    System.Assert.areEqual(mockParentLogTransactionId, Logger.getParentLogTransactionId(), 'Test has started under the wrong conditions');
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('getParentLogTransactionId', new Map<String, Object>{ 'output' => omnistudioOutput });

    System.Assert.areEqual(2, omnistudioOutput.size());
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(mockParentLogTransactionId, omnistudioOutput.get('parentLogTransactionId'));
  }

  @IsTest
  static void it_sets_parent_log_transaction_id_when_using_standard_approach() {
    System.Assert.isNull(Logger.getParentLogTransactionId(), 'Test has started under the wrong conditions');
    String mockParentLogTransactionId = 'some transaction id';

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance
      .call('setParentLogTransactionId', new Map<String, Object>{ 'parentLogTransactionId' => mockParentLogTransactionId });

    System.Assert.areEqual(1, returnedOutput.size());
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
    System.Assert.areEqual(mockParentLogTransactionId, Logger.getParentLogTransactionId());
  }

  @IsTest
  static void it_sets_parent_log_transaction_id_when_using_omnistudio_approach() {
    System.Assert.isNull(Logger.getParentLogTransactionId(), 'Test has started under the wrong conditions');
    String mockParentLogTransactionId = 'some transaction id';
    Map<String, Object> omnistudioInput = new Map<String, Object>{ 'parentLogTransactionId' => mockParentLogTransactionId };
    Map<String, Object> omnistudioOutput = new Map<String, Object>();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    callableLoggerInstance.call('setParentLogTransactionId', new Map<String, Object>{ 'input' => omnistudioInput, 'returnedOutput' => omnistudioOutput });

    System.Assert.areEqual(1, omnistudioOutput.size());
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(mockParentLogTransactionId, Logger.getParentLogTransactionId());
  }

  @IsTest
  static void it_gets_scenario_when_using_standard_approach() {
    String mockScenario = 'some scenario';
    Logger.setScenario(mockScenario);
    System.Assert.areEqual(mockScenario, Logger.getScenario(), 'Test has started under the wrong conditions');

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Map<String, Object> returnedOutput = (Map<String, Object>) callableLoggerInstance.call('getScenario', null);

    System.Assert.areEqual(2, returnedOutput.size());
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
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

    System.Assert.areEqual(2, omnistudioOutput.size());
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.areEqual(Logger.getScenario(), omnistudioOutput.get('scenario'));
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

    System.Assert.areEqual(1, returnedOutput.size());
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
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

    System.Assert.areEqual(1, omnistudioOutput.size());
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
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

    System.Assert.areEqual(1, returnedOutput.size());
    System.Assert.areEqual(true, returnedOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + returnedOutput);
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
    Object returnedValue = callableLoggerInstance.call('endScenario', new Map<String, Object>{ 'input' => omnistudioInput, 'output' => omnistudioOutput });

    System.Assert.areEqual(1, omnistudioOutput.size());
    System.Assert.areEqual(true, omnistudioOutput.get('isSuccess'), 'Expected isSuccess == true. Output received: ' + omnistudioOutput);
    System.Assert.isNull(Logger.getScenario());
  }

  @IsTest
  static void it_adds_new_entry_using_logging_level_enum() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Object returnedValue = callableLoggerInstance.call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message });

    System.Assert.isNotNull(returnedValue);
    System.Assert.isInstanceOfType(returnedValue, LogEntryEventBuilder.class);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedValue).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
  }

  @IsTest
  static void it_adds_new_entry_using_logging_level_name() {
    String loggingLevelName = System.LoggingLevel.FINE.name();
    String message = 'some log entry message';

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Object returnedValue = callableLoggerInstance.call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevelName, 'message' => message });

    System.Assert.isNotNull(returnedValue);
    System.Assert.isInstanceOfType(returnedValue, LogEntryEventBuilder.class);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedValue).getLogEntryEvent();
    System.Assert.areEqual(loggingLevelName, logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
  }

  @IsTest
  static void it_adds_new_entry_with_exception() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    System.Exception apexException = new System.DmlException('whoops');

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Object returnedValue = callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'exception' => apexException, 'loggingLevel' => loggingLevel, 'message' => message });

    System.Assert.isNotNull(returnedValue);
    System.Assert.isInstanceOfType(returnedValue, LogEntryEventBuilder.class);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedValue).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(apexException.getMessage(), logEntryEvent.ExceptionMessage__c);
    System.Assert.areEqual(apexException.getTypeName(), logEntryEvent.ExceptionType__c);
  }

  @IsTest
  static void it_adds_new_entry_with_record_id() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    Id recordId = System.UserInfo.getUserId();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Object returnedValue = callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'recordId' => recordId });

    System.Assert.isNotNull(returnedValue);
    System.Assert.isInstanceOfType(returnedValue, LogEntryEventBuilder.class);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedValue).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(recordId, logEntryEvent.RecordId__c);
  }

  @IsTest
  static void it_adds_new_entry_with_record() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    SObject record = new Schema.User(Id = System.UserInfo.getUserId());

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Object returnedValue = callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'record' => record });

    System.Assert.isNotNull(returnedValue);
    System.Assert.isInstanceOfType(returnedValue, LogEntryEventBuilder.class);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedValue).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(record), logEntryEvent.RecordJson__c);
  }

  @IsTest
  static void it_adds_new_entry_with_record_list() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    List<Schema.User> recordList = new List<Schema.User>{ new Schema.User(Id = System.UserInfo.getUserId()) };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Object returnedValue = callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'recordList' => recordList });

    System.Assert.isNotNull(returnedValue);
    System.Assert.isInstanceOfType(returnedValue, LogEntryEventBuilder.class);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedValue).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(recordList), logEntryEvent.RecordJson__c);
  }

  @IsTest
  static void it_adds_new_entry_with_record_map() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    Map<Id, Schema.User> recordMap = new Map<Id, Schema.User>{ System.UserInfo.getUserId() => new Schema.User(Id = System.UserInfo.getUserId()) };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Object returnedValue = callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'recordMap' => recordMap });

    System.Assert.isNotNull(returnedValue);
    System.Assert.isInstanceOfType(returnedValue, LogEntryEventBuilder.class);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedValue).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    System.Assert.areEqual(System.JSON.serializePretty(recordMap), logEntryEvent.RecordJson__c);
  }

  @IsTest
  static void it_adds_new_entry_with_tags() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    List<String> tags = new List<String>{ 'some-tag', 'another-tag' };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Object returnedValue = callableLoggerInstance
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message, 'tags' => tags });

    System.Assert.isNotNull(returnedValue);
    System.Assert.isInstanceOfType(returnedValue, LogEntryEventBuilder.class);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedValue).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
    tags.sort(); // Tags are auto-sorted by LogEntryEventBuilder
    System.Assert.areEqual(String.join(tags, '\n'), logEntryEvent.Tags__c);
  }

  @IsTest
  static void it_adds_new_entry_when_using_omnistudio_approach() {
    String loggingLevelName = System.LoggingLevel.FINE.name();
    String message = 'some log entry message';
    Map<String, Object> omnistudioInput = new Map<String, Object>{ 'loggingLevel' => loggingLevelName, 'message' => message };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Object returnedValue = callableLoggerInstance.call('newEntry', new Map<String, Object>{ 'input' => omnistudioInput });

    System.Assert.isNotNull(returnedValue);
    System.Assert.isInstanceOfType(returnedValue, LogEntryEventBuilder.class);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedValue).getLogEntryEvent();
    System.Assert.areEqual(loggingLevelName, logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
  }

  @IsTest
  static void it_saves_log_without_specifying_a_save_method() {
    Logger.info('some log entry that will be saved using the default save method').getLogEntryEvent();
    System.Assert.areEqual(1, Logger.getBufferSize());
    System.Assert.isNull(Logger.lastSaveMethodNameUsed);

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Object returnedValue = callableLoggerInstance.call('saveLog', null);

    System.Assert.isNull(returnedValue, 'No return value expected for Logger.saveLog(), received ' + returnedValue);
    System.Assert.areEqual(0, Logger.getBufferSize());
    System.Assert.areEqual(Logger.getUserSettings().DefaultSaveMethod__c, Logger.lastSaveMethodNameUsed);
  }

  @IsTest
  static void it_saves_log_with_specified_save_method() {
    Logger.info('some log entry that will be saved using the specified save method').getLogEntryEvent();
    System.Assert.areEqual(1, Logger.getBufferSize());
    System.Assert.isNull(Logger.lastSaveMethodNameUsed);
    String targetSaveMethodName = Logger.SaveMethod.SYNCHRONOUS_DML.name();

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Object returnedValue = callableLoggerInstance.call('saveLog', new Map<String, Object>{ 'saveMethodName' => targetSaveMethodName });

    System.Assert.isNull(returnedValue, 'No return value expected for Logger.saveLog(), received ' + returnedValue);
    System.Assert.areEqual(0, Logger.getBufferSize());
    System.Assert.areEqual(targetSaveMethodName, Logger.lastSaveMethodNameUsed);
  }

  @IsTest
  static void it_adds_and_saves_new_entry_when_using_omnistudio_approach() {
    System.Assert.isNull(Logger.lastSaveMethodNameUsed);
    String loggingLevelName = System.LoggingLevel.FINE.name();
    String message = 'some log entry message';
    Map<String, Object> omnistudioInput = new Map<String, Object>{ 'loggingLevel' => loggingLevelName, 'message' => message, 'saveLog' => true };

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Object returnedValue = callableLoggerInstance.call('newEntry', new Map<String, Object>{ 'input' => omnistudioInput });

    System.Assert.isNull(returnedValue, 'No return value expected for Logger.saveLog(), received ' + returnedValue);
    System.Assert.areEqual(0, Logger.getBufferSize());
    System.Assert.areEqual(Logger.getUserSettings().DefaultSaveMethod__c, Logger.lastSaveMethodNameUsed);
  }

  @IsTest
  static void it_supports_case_insensitive_strings_for_action_and_argument_names() {
    // The specific action being tested here (setParentLogTransactionId()) isn't really important - it could be any supported action.
    // What _is_ important is verifying that both the action name & argument names are not case-sensitive.
    System.Assert.isNull(Logger.getParentLogTransactionId(), 'Test has started under the wrong conditions');
    String mockParentLogTransactionId = 'some transaction id';

    System.Callable callableLoggerInstance = (System.Callable) System.Type.forName('CallableLogger').newInstance();
    Object returnedValue = callableLoggerInstance
      .call('SeTpArEnTlOgTrAnSaCtIoNiD', new Map<String, Object>{ 'PARENTlogTRANSACTIONiD' => mockParentLogTransactionId });

    System.Assert.isNull(returnedValue, 'No return value expected for Logger.getParentLogTransactionId(), received ' + returnedValue);
    System.Assert.areEqual(mockParentLogTransactionId, Logger.getParentLogTransactionId());
  }
}
