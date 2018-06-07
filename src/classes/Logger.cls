public without sharing class Logger {

    private static final LoggingLevel DEBUG_LOGGING_LEVEL = getUserDebugLoggingLevel();
    private static final String TRANSACTION_ID            = new Uuid().getValue();

    //private static Log log = new Log();
    private static Id logRecordId;
    //private static FileGenerator fileGenerator;
    private static List<LogEntryEvent__e> logEntries = new List<LogEntryEvent__e>();

    public static void addEntry(LoggingLevel loggingLevel, String message) {
        addEntry(loggingLevel, message, null, null, null, null, null);
    }

    public static void addEntry(String message) {
        addEntry(null, message, null, null, null, null, null);
    }

    public static void addEntry(String message, String className, String methodName) {
        addEntry(null, message, null, className, methodName, null, null);
    }

    public static void addEntry(LoggingLevel loggingLevel, String message, String className, String methodName) {
        addEntry(loggingLevel, message, null, className, methodName, null, null);
    }

    public static void addEntry(String message, String className, String methodName, Id parentId) {
        addEntry(null, message, null, className, methodName, parentId, null);
    }

    public static void addEntry(LoggingLevel loggingLevel, String message, String className, String methodName, Id parentId) {
        addEntry(null, message, null, className, methodName, parentId, null);
    }

    public static void addEntry(LoggingLevel loggingLevel, Exception ex) {
        addEntry(loggingLevel, null, ex, null, null, null, null);
    }

    public static void addEntry(Exception ex) {
        addEntry(null, null, ex, null, null, null, null);
    }

    public static void addEntry(Exception ex, String className, String methodName) {
        addEntry(null, null, ex, className, methodName, null, null);
    }

    public static void addEntry(LoggingLevel loggingLevel, Exception ex, String className, String methodName) {
        addEntry(null, null, ex, className, methodName, null, null);
    }

    public static void addEntry(Exception ex, String className, String methodName, Id parentId) {
        addEntry(null, null, ex, className, methodName, parentId, null);
    }

    public static void addEntry(LoggingLevel loggingLevel, Exception ex, String className, String methodName, Id parentId) {
        addEntry(loggingLevel, null, ex, className, methodName, parentId, null);
    }

private static Boolean meetsLogLevel(LoggingLevel userLoggingLevel, LoggingLevel logEntryLoggingLevel) {
    return logEntryLoggingLevel.ordinal() >= userLoggingLevel.ordinal();
}
private static void addEntry(LoggingLevel logLevel, String message, Exception ex, String className, String methodName, String processBuilderName, Id parentId) {
    if(logLevel == null) logLevel = LoggingLevel.DEBUG;

    LogEntry logEntry = new LogEntry(logLevel, message, ex, className, methodName, parentId);
    Boolean meetsLogLevel = meetsLogLevel(DEBUG_LOGGING_LEVEL, logLevel);
    if(getSettings().GenerateDebugStatements__c) System.debug(DEBUG_LOGGING_LEVEL, logEntry);
    //if(getSettings().GenerateLogFile__c) log.LogEntries.add(logEntry);
String type = ex != null ? 'Exception' : 'Debug';
if(type == 'Debug' && !getSettings().StoreDebugLogEntries__c) return;
if(type == 'Exception' && !getSettings().StoreExceptionLogEntries__c) throw ex;
    if(!getSettings().GenerateLogFile__c) return;
    if(!meetsLogLevel) return;

LogEntryEvent__e platformLogEntry = new LogEntryEvent__e(
    ClassName__c           = className,
    ExceptionLineNumber__c = ex == null ? null : ex.getLineNumber(),
    ExceptionStackTrace__c = ex == null ? null : ex.getStackTraceString(),
    ExceptionTypeName__c   = ex == null ? null : ex.getTypeName(),
    LoggingLevel__c        = logLevel.name(),
    Message__c             = ex == null ? message : ex.getMessage(),
    MethodName__c          = methodName,
    ParentId__c            = parentId,
    ProcessBuilderName__c  = processBuilderName,
    Timestamp__c           = logEntry.Timestamp,
    TransactionId__c       = TRANSACTION_ID,//log.TransactionId,
    Type__c                = type
);
logEntries.add(platformLogEntry);
    if(ex != null) {
        saveLog();
        //System.debug(EventBus.publish(platformLogEntry));
        throw ex;
    }
}

    public static void addEntries(List<String> messages) {
        for(String message : messages) addEntry(message, null, null);
    }

    @InvocableMethod(label='Add Log Entry' description='Stores a log entry for a process builder or flow')
    public static void addProcessBuilderEntries(List<LogEntry> processBuilderLogEntries) {
        for(LogEntry logEntry : processBuilderLogEntries) {
            addEntry(null, logEntry.Message, null, null, null, logEntry.ProcessBuilderName, null);
            //if(getSettings().GenerateDebugStatements__c) System.debug(DEBUG_LOGGING_LEVEL, logEntry);
            //if(getSettings().GenerateLogFile__c) log.LogEntries.add(logEntry); //TODO replace this with platform event object
        }
        saveLog();
    }

    public static void saveLog() {
        //if(!getSettings().GenerateLogFile__c) return;
        if(!logEntries.isEmpty()) EventBus.publish(logEntries);
    }

    private static LoggerSettings__c getSettings() {
        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();

        if(loggerSettings.Id != null) return loggerSettings;

        upsert LoggerSettings__c.getOrgDefaults();
        return LoggerSettings__c.getInstance();
    }

    private static LoggingLevel getUserDebugLoggingLevel() {
        String debugLoggingLevel = getSettings().DebugLoggingLevel__c;
        if(debugLoggingLevel != null) debugLoggingLevel = debugLoggingLevel.toUpperCase();

        switch on debugLoggingLevel {
            when 'NONE'   { return LoggingLevel.NONE; }
            when 'ERROR'  { return LoggingLevel.ERROR; }
            when 'WARN'   { return LoggingLevel.WARN; }
            when 'INFO'   { return LoggingLevel.INFO; }
            when 'DEBUG'  { return LoggingLevel.DEBUG; }
            when 'FINE'   { return LoggingLevel.FINE; }
            when 'FINER'  { return LoggingLevel.FINER; }
            when 'FINEST' { return LoggingLevel.FINEST; }
            when else     { return LoggingLevel.NONE; }
        }
    }

    public class LogEntry implements Comparable {

        @InvocableVariable(required=true)
        public String Message;
        @InvocableVariable(required=true label='Process Builder/Flow Name')
        public String ProcessBuilderName;
        @InvocableVariable(label='(Optional) Record ID')
        public String RecordId;

        public Exception Ex;
        public String ClassName;
        public LoggingLevel LoggingLevel;
        public String MethodName;
        public Datetime Timestamp;

        public LogEntry() {
            this.Timestamp = System.now();
        }

        private LogEntry(LoggingLevel loggingLevel, String message, Exception ex, String className, String methodName, Id recordId) {
            this.ClassName          = className;
            this.Ex                 = ex;
            this.LoggingLevel       = loggingLevel;
            this.Message            = message;
            this.MethodName         = methodName;
            this.ProcessBuilderName = processBuilderName;
            this.RecordId           = recordId;
            this.Timestamp          = System.now();
        }

        public Integer compareTo(Object compareTo) {
            Datetime compareToTimestamp = ((LogEntry)compareTo).Timestamp;
            if(this.Timestamp == compareToTimestamp) return 0;
            else if(this.Timestamp > compareToTimestamp) return 1;
            else return -1;
        }

    }

    private class Record {
        public Id Id;
        public String Name;
        public Record(Id id, String name) {
            this.Id = id;
            this.Name = name;
        }
    }

}