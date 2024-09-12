//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description A class that implements the standard interface `System.Callable`. This provides 2 benefits:
 *                1. A loosely-coupled way to optionally integrate with Nebula Logger (useful for ISVs/package developers).
 *                2. The ability to log in OmniStudio's OmniScripts & Integration Procedures.
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
  private static final String ARGUMENT_RECORD_LIST = 'recordList';
  private static final String ARGUMENT_RECORD_MAP = 'recordMap';
  private static final String ARGUMENT_SAVE_METHOD_NAME = 'saveMethodName';
  private static final String ARGUMENT_TAGS = 'tags';
  private static final String ARGUMENT_TRANSACTION_ID = 'transactionId';
  private static final String OMNISTUDIO_ARGUMENT_INPUT = 'input';
  private static final String OMNISTUDIO_ARGUMENT_OUTPUT = 'output';
  private static final String OMNISTUDIO_ARGUMENT_OPTIONS = 'options';
  private static final String OUTPUT_ARGUMENT_CALL_ERROR_MESSAGE = 'errorMessage';
  private static final String OUTPUT_ARGUMENT_CALL_IS_SUCCESS = 'isSuccess';

  /**
   * @description The one method required by the interface `System.Callable` description. It provides a `String`-based way to dynamically call Nebula Logger's code.
   * @param  action    The `String` name of the `Logger` method to call. The supported actions are
   * @param  arguments An instance of `Map<String, Object>` containing any named arguments expected by the `Logger` method being called
   * @return           The value returned by the `Logger` method called as an `Object` instance, or `null` if the method being called does not have a return value
   */
  global Object call(String action, Map<String, Object> arguments) {
    arguments = arguments ?? new Map<String, Object>();
    arguments.remove(null);

    CallableHandler handler;
    Map<String, Object> input;
    Map<String, Object> output;
    // if (isOmniStudioCall(arguments)) {
    if (arguments.containsKey(OMNISTUDIO_ARGUMENT_INPUT) || arguments.containsKey(OMNISTUDIO_ARGUMENT_OUTPUT)) {
      handler = new OmniStudioCallableHandler();
      input = (Map<String, Object>) arguments.get(OMNISTUDIO_ARGUMENT_INPUT);
      output = (Map<String, Object>) arguments.get(OMNISTUDIO_ARGUMENT_OUTPUT);
    } else {
      handler = new StandardCallableHandler();
      input = arguments;
      output = new Map<String, Object>();
    }

    handler.handleCall(action, input, output);

    return output;
  }

  @SuppressWarnings('PMD.ApexDoc')
  private abstract class CallableHandler {
    public virtual void handleCall(String action, Map<String, Object> input, Map<String, Object> output) {
      Boolean isSuccess = true;
      String errorMessage;

      switch on action {
        // Methods for transaction IDs / parent transaction IDs
        when 'getTransactionId' {
          output.put(ARGUMENT_TRANSACTION_ID, Logger.getTransactionId());
        }
        when 'getParentLogTransactionId' {
          output.put(ARGUMENT_PARENT_LOG_TRANSACTION_ID, Logger.getParentLogTransactionId());
        }
        when 'setParentLogTransactionId' {
          Logger.setParentLogTransactionId((String) input.get(ARGUMENT_PARENT_LOG_TRANSACTION_ID));
        }
        // Methods for scenario-based logging
        when 'getScenario' {
          output.put(ARGUMENT_SCENARIO, Logger.getScenario());
        }
        when 'setScenario' {
          Logger.setScenario((String) input.get(ARGUMENT_SCENARIO));
        }
        when 'endScenario' {
          Logger.endScenario((String) input.get(ARGUMENT_SCENARIO));
        }
        when else {
          isSuccess = false;
          errorMessage = 'Unknown action: ' + action;
        }
      }

      output.put(OUTPUT_ARGUMENT_CALL_IS_SUCCESS, isSuccess);
      if (String.isNotBlank(errorMessage)) {
        output.put(OUTPUT_ARGUMENT_CALL_ERROR_MESSAGE, errorMessage);
      }
    }

    protected LogEntryEventBuilder newEntry(Map<String, Object> arguments) {
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

    protected void saveLog(Map<String, Object> arguments) {
      String saveMethodName = ((String) arguments.get(ARGUMENT_SAVE_METHOD_NAME)) ?? Logger.getUserSettings().DefaultSaveMethod__c;
      Logger.saveLog(saveMethodName);
    }
  }

  // Handler used when Apex developers/ISVs/package creators are directly creating
  // interacting with `CallableLogger` (i.e., anyone not using this for OmniStudio)
  @SuppressWarnings('PMD.ApexDoc')
  private class StandardCallableHandler extends CallableHandler {
    public override void handleCall(String action, Map<String, Object> input, Map<String, Object> output) {
      switch on action {
        // Methods for adding entries & saving
        when 'newEntry' {
          this.newEntry(input);
          output.put(OUTPUT_ARGUMENT_CALL_IS_SUCCESS, true);
        }
        when 'saveLog' {
          this.saveLog(input);
          output.put(OUTPUT_ARGUMENT_CALL_IS_SUCCESS, true);
        }
        when else {
          super.handleCall(action, input, output);
        }
      }
    }
  }

  // Handler used when OmniStudio designers & developers are using `CallableLogger` for logging in OmniStudio
  @SuppressWarnings('PMD.ApexDoc')
  private class OmniStudioCallableHandler extends CallableHandler {
    public override void handleCall(String action, Map<String, Object> input, Map<String, Object> output) {
      switch on action {
        // TODO revisit if using 'addnewentry' and ''addnewentry' is the best approach for OmniStudio:
        //  - For omniscripts, there's no state, so calling saveLog() doesn't make sense
        //  - For integration procedures, there IS state, so devs may want to call newEntry() and saveLog()
        when 'addNewEntry' {
          this.newEntry(input);
          output.put(OUTPUT_ARGUMENT_CALL_IS_SUCCESS, true);
        }
        when 'saveNewEntry' {
          this.newEntry(input);
          Logger.saveLog();
          output.put(OUTPUT_ARGUMENT_CALL_IS_SUCCESS, true);
        }
        when else {
          super.handleCall(action, input, output);
        }
      }
    }
  }

  // OmniStudio / OmniScript docs https://help.salesforce.com/s/articleView?id=sf.os_callable_implementations.htm&type=5
  private Boolean isOmniStudioCall(Map<String, Object> arguments) {
    return arguments.containsKey(OMNISTUDIO_ARGUMENT_INPUT) || arguments.containsKey(OMNISTUDIO_ARGUMENT_OUTPUT);
  }
}
