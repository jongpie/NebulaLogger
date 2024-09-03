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
      ((System.Callable) System.Type.forName('CallableLogger').newInstance()).call(fakeActionName, null);
    } catch (System.IllegalArgumentException ex) {
      thrownException = ex;
    }

    System.Assert.isNotNull(thrownException);
    System.Assert.areEqual('Unsupported action: ' + fakeActionName, thrownException.getMessage());
  }

  @IsTest
  static void it_gets_transaction_id() {
    System.Assert.isNotNull(Logger.getTransactionId(), 'Test has started under the wrong conditions');

    Object returnedValue = ((System.Callable) System.Type.forName('CallableLogger').newInstance()).call('getTransactionId', null);

    System.Assert.isNotNull(returnedValue);
    System.Assert.areEqual(Logger.getTransactionId(), returnedValue);
  }

  @IsTest
  static void it_gets_parent_log_transaction_id() {
    String mockParentLogTransactionId = 'some transaction id';
    Logger.setParentLogTransactionId(mockParentLogTransactionId);
    System.Assert.areEqual(mockParentLogTransactionId, Logger.getParentLogTransactionId(), 'Test has started under the wrong conditions');

    Object returnedValue = ((System.Callable) System.Type.forName('CallableLogger').newInstance()).call('getParentLogTransactionId', null);

    System.Assert.isNotNull(returnedValue);
    System.Assert.areEqual(mockParentLogTransactionId, returnedValue);
  }

  @IsTest
  static void it_sets_parent_log_transaction_id() {
    System.Assert.isNull(Logger.getParentLogTransactionId(), 'Test has started under the wrong conditions');
    String mockParentLogTransactionId = 'some transaction id';

    Object returnedValue = ((System.Callable) System.Type.forName('CallableLogger').newInstance())
      .call('setParentLogTransactionId', new Map<String, Object>{ 'parentLogTransactionId' => mockParentLogTransactionId });

    System.Assert.isNull(returnedValue, 'No return value expected for Logger.getParentLogTransactionId()');
    System.Assert.areEqual(mockParentLogTransactionId, Logger.getParentLogTransactionId());
  }

  @IsTest
  static void it_gets_scenario() {
    String mockScenario = 'some scenario';
    Logger.setScenario(mockScenario);
    System.Assert.areEqual(mockScenario, Logger.getScenario(), 'Test has started under the wrong conditions');

    Object returnedValue = ((System.Callable) System.Type.forName('CallableLogger').newInstance()).call('getScenario', null);

    System.Assert.isNotNull(returnedValue);
    System.Assert.areEqual(Logger.getScenario(), returnedValue);
  }

  @IsTest
  static void it_sets_scenario() {
    System.Assert.isNull(Logger.getScenario(), 'Test has started under the wrong conditions');
    String mockScenario = 'some scenario';

    Object returnedValue = ((System.Callable) System.Type.forName('CallableLogger').newInstance())
      .call('setScenario', new Map<String, Object>{ 'scenario' => mockScenario });

    System.Assert.isNull(returnedValue);
    System.Assert.areEqual(mockScenario, Logger.getScenario());
  }

  @IsTest
  static void it_ends_scenario() {
    String mockScenario = 'some scenario';
    Logger.setScenario(mockScenario);
    System.Assert.areEqual(mockScenario, Logger.getScenario(), 'Test has started under the wrong conditions');

    Object returnedValue = ((System.Callable) System.Type.forName('CallableLogger').newInstance())
      .call('endScenario', new Map<String, Object>{ 'scenario' => mockScenario });

    System.Assert.isNull(returnedValue);
    System.Assert.isNull(Logger.getScenario());
  }

  @IsTest
  static void it_adds_new_entry() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';

    Object returnedValue = ((System.Callable) System.Type.forName('CallableLogger').newInstance())
      .call('newEntry', new Map<String, Object>{ 'loggingLevel' => loggingLevel, 'message' => message });

    System.Assert.isNotNull(returnedValue);
    System.Assert.isInstanceOfType(returnedValue, LogEntryEventBuilder.class);
    LogEntryEvent__e logEntryEvent = ((LogEntryEventBuilder) returnedValue).getLogEntryEvent();
    System.Assert.areEqual(loggingLevel.name(), logEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(message, logEntryEvent.Message__c);
  }

  @IsTest
  static void it_adds_new_entry_with_exception() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    System.Exception apexException = new System.DmlException('whoops');

    Object returnedValue = ((System.Callable) System.Type.forName('CallableLogger').newInstance())
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

    Object returnedValue = ((System.Callable) System.Type.forName('CallableLogger').newInstance())
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

    Object returnedValue = ((System.Callable) System.Type.forName('CallableLogger').newInstance())
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
    System.Assert.fail('TODO');
  }

  @IsTest
  static void it_adds_new_entry_with_record_map() {
    System.Assert.fail('TODO');
  }

  @IsTest
  static void it_adds_new_entry_with_tags() {
    System.LoggingLevel loggingLevel = System.LoggingLevel.FINE;
    String message = 'some log entry message';
    List<String> tags = new List<String>{ 'some-tag', 'another-tag' };

    Object returnedValue = ((System.Callable) System.Type.forName('CallableLogger').newInstance())
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
  static void it_saves_log() {
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    LogEntryEvent__e createdLogEntryEvent = Logger.info('some log entry that will be saved using EVENT_BUS by default').getLogEntryEvent();
    System.Assert.areEqual(1, Logger.getBufferSize());

    Object returnedValue = ((System.Callable) System.Type.forName('CallableLogger').newInstance()).call('saveLog', null);

    System.Assert.isNull(returnedValue);
    System.Assert.areEqual(0, Logger.getBufferSize());
    System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
    LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
    System.Assert.areEqual(createdLogEntryEvent, publishedLogEntryEvent);
  }

  @IsTest
  static void it_saves_log_with_specified_save_method() {
    System.Assert.fail('TODO');
  }
}
