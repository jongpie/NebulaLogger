//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description A class that implements the standard interface `System.Callable` to provide a loosely-coupled way
 *              to interact with Nebula Logger. This can be used for OmniStudio, as well as for optionally & dynamically
 *              integrating other packages/code with Nebula Logger's code (when available).
 * @see Logger
 * @see LogEntryEventBuilder
 */
@SuppressWarnings('PMD.AvoidGlobalModifier')
global without sharing class CallableLogger implements System.Callable {
  private static final String ARGUMENT_EXCEPTION = 'exception'.toLowerCase();
  private static final String ARGUMENT_LOGGING_LEVEL = 'loggingLevel'.toLowerCase();
  private static final String ARGUMENT_MESSAGE = 'message'.toLowerCase();
  private static final String ARGUMENT_PARENT_LOG_TRANSACTION_ID = 'parentLogTransactionId'.toLowerCase();
  private static final String ARGUMENT_SCENARIO = 'scenario'.toLowerCase();
  private static final String ARGUMENT_RECORD_ID = 'recordId'.toLowerCase();
  private static final String ARGUMENT_RECORD = 'record'.toLowerCase();
  private static final String ARGUMENT_RECORD_LIST = 'recordList'.toLowerCase();
  private static final String ARGUMENT_RECORD_MAP = 'recordMap'.toLowerCase();
  private static final String ARGUMENT_SAVE_METHOD_NAME = 'saveMethodName'.toLowerCase();
  private static final String ARGUMENT_TAGS = 'tags'.toLowerCase();

  /**
   * @description The one method required by the interface `System.Callable` description. It provides a `String`-based way to dynamically call Nebula Logger's code.
   * @param  action    The `String` name of the `Logger` method to call. The supported actions are
   * @param  arguments An instance of `Map<String, Object>` containing any named arguments expected by the `Logger` method being called
   * @return           The value returned by the `Logger` method called as an `Object` instance, or `null` if the method being called does not have a return value
   */
  global Object call(String action, Map<String, Object> arguments) {
    arguments = getCleansedArguments(arguments);

    switch on action?.toLowerCase() {
      // Methods for transaction IDs / parent transaction IDs
      when 'gettransactionid' {
        return Logger.getTransactionId();
      }
      when 'getparentlogtransactionid' {
        return Logger.getParentLogTransactionId();
      }
      when 'setparentlogtransactionid' {
        Logger.setParentLogTransactionId((String) arguments.get(ARGUMENT_PARENT_LOG_TRANSACTION_ID));
        return null;
      }
      // Methods for scenario-based logging
      when 'getscenario' {
        return Logger.getScenario();
      }
      when 'setscenario' {
        Logger.setScenario((String) arguments.get('scenario'));
        return null;
      }
      when 'endscenario' {
        Logger.endScenario((String) arguments.get('scenario'));
        return null;
      }
      // Methods for adding entries & saving
      when 'newentry' {
        return newEntry(arguments);
      }
      when 'savelog' {
        saveLog(arguments);
        return null;
      }
      when else {
        throw new System.IllegalArgumentException('Unsupported action: ' + action);
      }
    }
  }

  private Map<String, Object> getCleansedArguments(Map<String, Object> originalArguments) {
    originalArguments = originalArguments ?? new Map<String, Object>();
    originalArguments.remove(null);

    Map<String, Object> cleansedArguments = new Map<String, Object>();
    for (String key : originalArguments.keySet()) {
      cleansedArguments.put(key.toLowerCase(), originalArguments.get(key));
    }
    return cleansedArguments;
  }

  private LogEntryEventBuilder newEntry(Map<String, Object> arguments) {
    // The value of loggingLevel could be either a string name or enum value,
    // so coerce it to a string for consistency
    String loggingLevelName = '' + arguments.get(ARGUMENT_LOGGING_LEVEL);
    System.LoggingLevel loggingLevel = Logger.getLoggingLevel(loggingLevelName);
    String message = (String) arguments.get(ARGUMENT_MESSAGE);

    LogEntryEventBuilder logEntryEventBuilder = Logger.newEntry(loggingLevel, message);

    if (arguments.containsKey(ARGUMENT_EXCEPTION)) {
      logEntryEventBuilder.setExceptionDetails((System.Exception) arguments.get(ARGUMENT_EXCEPTION));
    }
    if (arguments.containsKey(ARGUMENT_RECORD_ID)) {
      logEntryEventBuilder.setRecord((String) arguments.get(ARGUMENT_RECORD_ID));
    }
    if (arguments.containsKey(ARGUMENT_RECORD)) {
      logEntryEventBuilder.setRecord((SObject) arguments.get(ARGUMENT_RECORD));
    }
    if (arguments.containsKey(ARGUMENT_RECORD_LIST)) {
      logEntryEventBuilder.setRecord((List<SObject>) arguments.get(ARGUMENT_RECORD_LIST));
    }
    if (arguments.containsKey(ARGUMENT_RECORD_MAP)) {
      logEntryEventBuilder.setRecord((Map<Id, SObject>) arguments.get(ARGUMENT_RECORD_MAP));
    }
    if (arguments.containsKey(ARGUMENT_TAGS)) {
      logEntryEventBuilder.addTags((List<String>) arguments.get(ARGUMENT_TAGS));
    }

    return logEntryEventBuilder;
  }

  private void saveLog(Map<String, Object> arguments) {
    String saveMethodName = ((String) arguments.get(ARGUMENT_SAVE_METHOD_NAME)) ?? Logger.getUserSettings().DefaultSaveMethod__c;
    Logger.saveLog(saveMethodName);
  }
}
