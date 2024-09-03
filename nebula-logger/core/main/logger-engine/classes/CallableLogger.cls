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
@SuppressWarnings('PMD.AvoidGlobalModifier')
global without sharing class CallableLogger implements System.Callable {
  private static final String ARGUMENT_EXCEPTION = 'exception';
  private static final String ARGUMENT_LOGGING_LEVEL = 'loggingLevel';
  private static final String ARGUMENT_MESSAGE = 'message';
  private static final String ARGUMENT_PARENT_LOG_TRANSACTION_ID = 'parentLogTransactionId';
  private static final String ARGUMENT_SCENARIO = 'scenario';
  private static final String ARGUMENT_RECORD_ID = 'recordId';
  private static final String ARGUMENT_RECORD = 'record';
  private static final String ARGUMENT_SAVE_METHOD_NAME = 'saveMethodName';
  private static final String ARGUMENT_TAGS = 'tags';

  global Object call(String action, Map<String, Object> arguments) {
    arguments = arguments ?? new Map<String, Object>();

    // TODO consider using .toLowerCase() to avoid casing bugs
    switch on action {
      // Transaction ID-related methods
      when 'getTransactionId' {
        return Logger.getTransactionId();
      }
      when 'getParentLogTransactionId' {
        return Logger.getParentLogTransactionId();
      }
      when 'setParentLogTransactionId' {
        Logger.setParentLogTransactionId((String) arguments.get(ARGUMENT_PARENT_LOG_TRANSACTION_ID));
        return null;
      }
      // Scenario-based logging methods
      when 'getScenario' {
        return Logger.getScenario();
      }
      when 'setScenario' {
        Logger.setScenario((String) arguments.get('scenario'));
        return null;
      }
      when 'endScenario' {
        Logger.endScenario((String) arguments.get('scenario'));
        return null;
      }
      // Logging & save methods
      when 'newEntry' {
        return newEntry(arguments);
      }
      when 'saveLog' {
        saveLog(arguments);
        return null;
      }
      when else {
        throw new System.IllegalArgumentException('Unsupported action: ' + action);
      }
    }
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

  private void saveLog(Map<String, Object> arguments) {
    String saveMethodName = ((String) arguments.get(ARGUMENT_SAVE_METHOD_NAME)) ?? Logger.getUserSettings().DefaultSaveMethod__c;
    Logger.saveLog(saveMethodName);
  }
}
