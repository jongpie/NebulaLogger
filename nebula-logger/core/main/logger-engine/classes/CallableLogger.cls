// TODO determine if this works in a managed package
// If so, change from public to global

// https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_interface_System_Callable.htm#apex_interface_System_Callable_Example

//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Callable class used that can be used for loosely-couple dependencies & for OmniStudio
 * @see Logger
 * @see LogEntryEventBuilder
 */
public without sharing class CallableLogger implements System.Callable {
  private static final String ARGUMENT_EXCEPTION = 'exception';
  private static final String ARGUMENT_LOGGING_LEVEL = 'loggingLevel';
  private static final String ARGUMENT_MESSAGE = 'message';
  private static final String ARGUMENT_PARENT_LOG_TRANSACTION_ID = 'parentLogTransactionId';
  private static final String ARGUMENT_SCENARIO = 'scenario';
  private static final String ARGUMENT_RECORD_ID = 'recordId';
  private static final String ARGUMENT_RECORD = 'record';
  private static final String ARGUMENT_SAVE_METHOD = 'saveMethod';
  private static final String ARGUMENT_TAGS = 'tags';

  public Object call(String action, Map<String, Object> arguments) {
    arguments = arguments ?? new Map<String, Object>();

    // TODO consider using .toLowerCase() to avoid casing bugs
    switch on action {
      when 'getTransactionId' {
        return Logger.getTransactionId();
      }
      when 'getParentLogTransactionId' {
        return Logger.getParentLogTransactionId();
      }
      when 'setParentLogTransactionId' {
        Logger.setParentLogTransactionId((String) arguments.get(ARGUMENT_PARENT_LOG_TRANSACTION_ID));
      }
      when 'newEntry' {
        return newEntry(arguments);
      }
      when 'saveLog' {
        return saveLog(arguments);
      }
      when 'getScenario' {
        return Logger.getScenario();
      }
      when 'setScenario' {
        Logger.setScenario((String) arguments.get('scenario'));
      }
      when 'endScenario' {
        Logger.endScenario((String) arguments.get('scenario'));
      }
      when else {
        throw new System.IllegalArgumentException('Unsupported action: ' + action);
      }
    }
    return null;
  }

  private LogEntryEventBuilder newEntry(Map<String, Object> arguments) {
    System.LoggingLevel loggingLevel = (System.LoggingLevel) arguments.get(ARGUMENT_LOGGING_LEVEL);
    String message = (String) arguments.get(ARGUMENT_MESSAGE);

    return Logger.newEntry(loggingLevel, message)
      .setExceptionDetails((System.Exception) arguments.get(ARGUMENT_EXCEPTION))
      .setRecordId((String) arguments.get(ARGUMENT_RECORD_ID))
      .setRecord((SObject) arguments.get(ARGUMENT_RECORD))
      .addTags((List<String>) arguments.get(ARGUMENT_TAGS));
  }

  private String saveLog(Map<String, Object> arguments) {
    String saveMethodName = (String) arguments.get(ARGUMENT_SAVE_METHOD);
    // TODO decide if there should be support for specifying a save method
    // If so, need to handle using EVENT_BUS as fallback
    Logger.saveLog();
    return Logger.getTransactionId();
  }
}
