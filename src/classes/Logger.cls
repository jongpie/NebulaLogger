public without sharing class Logger {

    private static final String TRANSACTION_ID = new Uuid().getValue();

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

    private static void addEntry(LoggingLevel logEntryLoggingLevel, String message, Exception ex, String className, String methodName, String processBuilderName, Id parentId) {
        if(logEntryLoggingLevel == null) logEntryLoggingLevel = LoggingLevel.DEBUG;
        if(ex != null) message = ex.getMessage();

        if(getSettings().GenerateDebugStatements__c) System.debug(logEntryLoggingLevel, message);
        Boolean meetsLoggingLevel = meetsLoggingLevel(getUserLoggingLevel(), logEntryLoggingLevel);

        String type = ex == null ? 'Debug' : 'Exception';
        if(type == 'Debug' && !getSettings().StoreDebugLogEntries__c) return;
        if(type == 'Exception' && !getSettings().StoreExceptionLogEntries__c) throw ex;

        if(!meetsLoggingLevel(getUserLoggingLevel(), logEntryLoggingLevel)) return;

        LogEntryEvent__e platformLogEntry = new LogEntryEvent__e(
            ClassName__c           = className,
            ExceptionLineNumber__c = ex == null ? null : ex.getLineNumber(),
            ExceptionStackTrace__c = ex == null ? null : ex.getStackTraceString(),
            ExceptionTypeName__c   = ex == null ? null : ex.getTypeName(),
            LoggingLevel__c        = logEntryLoggingLevel.name(),
            Message__c             = message,
            MethodName__c          = methodName,
            ParentId__c            = parentId,
            ProcessBuilderName__c  = processBuilderName,
            SourceType__c          = processBuilderName != null ? 'Process Builder' : 'Apex',
            Timestamp__c           = System.now(),
            TransactionId__c       = TRANSACTION_ID,
            Type__c                = type,
            UserLoggingLevel__c    = getUserLoggingLevel().name()
        );
        logEntries.add(platformLogEntry);

        if(ex != null) {
            saveLog();
            throw ex;
        }
    }

    public static void addEntries(List<String> messages) {
        for(String message : messages) addEntry(message, null, null);
    }

    @InvocableMethod(label='Add Log Entry' description='Stores a log entry for a process builder or flow')
    public static void addProcessBuilderEntries(List<ProcessBuilderLogEntry> processBuilderLogEntries) {
        for(ProcessBuilderLogEntry logEntry : processBuilderLogEntries) {
            LoggingLevel loggingLevel = getLoggingLevel(logEntry.LoggingLevelName);
            addEntry(loggingLevel, logEntry.Message, null, null, null, logEntry.ProcessBuilderName, logEntry.ParentId);
        }
        saveLog();
    }

    public static void saveLog() {
        if(!logEntries.isEmpty()) EventBus.publish(logEntries);
    }

    private static LoggerSettings__c getSettings() {
        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();

        if(loggerSettings.Id != null) return loggerSettings;

        upsert LoggerSettings__c.getOrgDefaults();
        return LoggerSettings__c.getInstance();
    }

    private static LoggingLevel getLoggingLevel(String loggingLevelName) {
        switch on loggingLevelName.toUpperCase() {
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

    private static LoggingLevel getUserLoggingLevel() {
        return getLoggingLevel(getSettings().LoggingLevel__c);
    }

    private static Boolean meetsLoggingLevel(LoggingLevel userLoggingLevel, LoggingLevel logEntryLoggingLevel) {
        return logEntryLoggingLevel.ordinal() >= userLoggingLevel.ordinal();
    }

    public class ProcessBuilderLogEntry {

        @InvocableVariable(required=true)
        public String Message;
        @InvocableVariable(required=true label='Process Builder/Flow Name')
        public String ProcessBuilderName;
        @InvocableVariable(label='(Optional) Logging Level')
        public String LoggingLevelName;
        @InvocableVariable(label='(Optional) Parent Record ID')
        public Id ParentId;

        public Datetime Timestamp;

        public ProcessBuilderLogEntry() {
            this.Timestamp = System.now();
        }

    }

}