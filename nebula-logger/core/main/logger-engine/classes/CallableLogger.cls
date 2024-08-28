// TODO determine if this works in a managed package
// If so, change from public to global

// https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_interface_System_Callable.htm#apex_interface_System_Callable_Example
public without sharing class CallableLogger implements System.Callable {
  public static final Actions ACTIONS = new Actions();
  public static final Arguments ARGUMENTS = new Arguments();

  private static final Map<String, Object> supportedLoggingArguments = new Map<String, Object>{
    'exception' => System.Exception.class,
    'message' => String.class,
    'parentLogTransactionId' => String.class,
    'scenario' => String.class,
    'recordId' => String.class,
    'record' => SObject.class,
    'tags' => List<String>.class
  };

  public class SupportedActions {
    public final Map<String, Map<String, System.Type>> actionNameToArgumentTypes = new Map<String, Map<String, System.Type>>{
      'saveLog' => new Map<String, System.Type>{ ARGUMENT_PARENT_LOG_TRANSACTION_ID => String.class }
    };
  }

  public class Actions {
    public final String getTransactionId = 'getTransactionId';
    public final String getParentLogTransactionId = 'getParentLogTransactionId';
    public final String setParentLogTransactionId = 'setParentLogTransactionId';
    public final String error = 'error';
    public final String warn = 'warn';
    public final String info = 'info';
    public final String debug = 'debug';
    public final String fine = 'fine';
    public final String finer = 'finer';
    public final String finest = 'finest';
    public final String saveLog = 'saveLog';
    public final String setScenario = 'setScenario';
    public final String endScenario = 'endScenario';
  }

  public class Arguments {
    public final String apexException = 'apexException';
    public final String message = 'message';
    public final String recordId = 'recordId';
    public final String record = 'record';
    public final String scenario = 'scenario';
    public final String tags = 'tags';

    public final Map<String, Map<String, System.Type>> actionNameToArgumentTypes = new Map<String, Map<String, System.Type>>{
      ACTIONS.saveLog => new Map<String, System.Type>{ ARGUMENT_PARENT_LOG_TRANSACTION_ID => String.class }
    };
  }

  // Supported action names
  public static final String ACTION_GET_TRANSACTION_ID = 'getTransactionId';
  public static final String ACTION_GET_PARENT_LOG_TRANSACTION_ID = 'getParentLogTransactionId';
  public static final String ACTION_SET_PARENT_LOG_TRANSACTION_ID = 'setParentLogTransactionId';
  public static final String ACTION_ERROR = 'error';
  public static final String ACTION_WARN = 'warn';
  public static final String ACTION_INFO = 'info';
  public static final String ACTION_DEBUG = 'debug';
  public static final String ACTION_FINE = 'fine';
  public static final String ACTION_FINER = 'finer';
  public static final String ACTION_FINEST = 'finest';
  public static final String ACTION_SAVE_LOG = 'saveLog';
  public static final String ACTION_SET_SCENARIO = 'setScenario';
  public static final String ACTION_END_SCENARIO = 'endScenario';
  // Supported argument names
  public static final String ARGUMENT_EXCEPTION = 'exception';
  public static final String ARGUMENT_MESSAGE = 'message';
  public static final String ARGUMENT_PARENT_LOG_TRANSACTION_ID = 'parentLogTransactionId';
  public static final String ARGUMENT_SCENARIO = 'scenario';
  public static final String ARGUMENT_RECORD_ID = 'recordId';
  public static final String ARGUMENT_RECORD = 'record';
  public static final String ARGUMENT_TAGS = 'tags';

  public Object call(String action, Map<String, Object> arguments) {
    arguments = arguments ?? new Map<String, Object>();

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
      when 'error', 'warn', 'info', 'debug', 'fine', 'finer', 'finest' {
        return newEntry(action, arguments);
      }
      when 'saveLog' {
        // TODO decide if there should be support for specifying a save method
        // If so, need to handle using EVENT_BUS as fallback
        Logger.saveLog();
        return Logger.getTransactionId();
      }
      when 'setScenario' {
        Logger.setScenario((String) arguments.get(ARGUMENT_SCENARIO));
      }
      when 'endScenario' {
        Logger.endScenario((String) arguments.get(ARGUMENT_SCENARIO));
      }
      when else {
        throw new System.IllegalArgumentException('Unsupported action: ' + action);
      }
    }
    return null;
  }

  private LogEntryEventBuilder newEntry(String loggingLevelName, Map<String, Object> arguments) {
    System.LoggingLevel loggingLevel = Logger.getLoggingLevel(loggingLevelName);
    String message = (String) arguments.get(ARGUMENT_MESSAGE);

    return Logger.newEntry(loggingLevel, message)
      .setExceptionDetails((System.Exception) arguments.get(ARGUMENT_EXCEPTION))
      .setRecordId((String) arguments.get(ARGUMENT_RECORD_ID))
      .setRecord((SObject) arguments.get(ARGUMENT_RECORD))
      .addTags((List<String>) arguments.get(ARGUMENT_TAGS));

    // LogEntryEventBuilder logEntryEventBuilder = Logger.newEntry(loggingLevel, message);

    // System.Exception apexException = (System.Exception) arguments.get(ARGUMENT_EXCEPTION);
    // if (apexException != null) {
    //     logEntryEventBuilder.setExceptionDetails(apexException);
    // }

    // String recordId = (String) arguments.get(ARGUMENT_RECORD_ID);
    // if (recordId != null) {
    //     logEntryEventBuilder.setRecordId(recordId);
    // }

    // SObject record = (SObject) arguments.get(ARGUMENT_RECORD);
    // if (record != null) {
    //   logEntryEventBuilder.setRecord(record);
    // }

    // List<String> tags = (List<String>) arguments.get(ARGUMENT_TAGS);
    // if (tags != null) {
    //   logEntryEventBuilder.addTags(tags);
    // }

    // return logEntryEventBuilder;
  }
}
