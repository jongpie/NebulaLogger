/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class Logger {

    private static final String TRANSACTION_ID = generateUuid();

    private static List<LogEntryEvent__e> logEntries = new List<LogEntryEvent__e>();

    public static String getTransactionId() {
        return TRANSACTION_ID;
    }

    public static String addDebugEntry(String message, String className, String methodName) {
        return addEntry(null, message, null, className, methodName, null, null);
    }

    public static String addDebugEntry(LoggingLevel loggingLevel, String message, String className, String methodName) {
        return addEntry(loggingLevel, message, null, className, methodName, null, null);
    }

    public static String addDebugEntry(String message, String className, String methodName, Id parentId) {
        return addEntry(null, message, null, className, methodName, null, parentId);
    }

    public static String addDebugEntry(LoggingLevel loggingLevel, String message, String className, String methodName, Id parentId) {
        return addEntry(LoggingLevel, message, null, className, methodName, null, parentId);
    }

    public static String addExceptionEntry(Exception ex, String className, String methodName) {
        return addEntry(null, null, ex, className, methodName, null, null);
    }

    public static String addExceptionEntry(LoggingLevel loggingLevel, Exception ex, String className, String methodName) {
        return addEntry(loggingLevel, null, ex, className, methodName, null, null);
    }

    public static String addExceptionEntry(Exception ex, String className, String methodName, Id parentId) {
        return addEntry(null, null, ex, className, methodName, null, parentId);
    }

    public static String addExceptionEntry(LoggingLevel loggingLevel, Exception ex, String className, String methodName, Id parentId) {
        return addEntry(loggingLevel, null, ex, className, methodName, null, parentId);
    }

    public static void addFlowEntries(List<FlowLogEntry> flowLogEntries) {
        for(FlowLogEntry flowLogEntry : flowLogEntries) {
            LoggingLevel loggingLevel;
            if(!String.isBlank(flowLogEntry.LoggingLevelName)) loggingLevel = getLoggingLevel(flowLogEntry.LoggingLevelName);
            addEntry(loggingLevel, flowLogEntry.Message, null, null, null, flowLogEntry.FlowName, flowLogEntry.ParentId);
        }
    }

    public static LoggingLevel getLoggingLevel(String loggingLevelName) {
        if(loggingLevelName != null) loggingLevelName = loggingLevelName.toUpperCase();

        switch on loggingLevelName {
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

    @InvocableMethod(label='Save Log' description='Saves any log entries that have been generated')
    public static void saveLog() {
        if(logEntries.isEmpty()) return;

        EventBus.publish(logEntries);
        logEntries.clear();
    }

    private static String generateUuid() {
        Blob generatedBlob      = Crypto.generateAesKey(128);
        String unformattedValue = EncodingUtil.convertTohex(generatedBlob);
        // Remove any non-alphanumeric characters. Should be unnecessary, but better to be safe than sorry.
        unformattedValue = unformattedValue.replaceAll('[^a-zA-Z0-9]', '');

        String formattedValue = unformattedValue.substring(0, 8)
            + '-' + unformattedValue.substring(8, 12)
            + '-' + unformattedValue.substring(12, 16)
            + '-' + unformattedValue.substring(16, 20)
            + '-' + unformattedValue.substring(20);

        return formattedValue.toUpperCase();
    }

    private static LoggerSettings__c getSettings() {
        LoggerSettings__c loggerSettings = LoggerSettings__c.getInstance();

        // If there's an ID, then the settings exist at some level (org, profile or user)
        if(loggerSettings.Id != null) return loggerSettings;

        // No ID -- > no settings have been configured in the org, so create org defaults
        upsert LoggerSettings__c.getOrgDefaults();
        return LoggerSettings__c.getInstance();
    }

    private static LoggingLevel getUserLoggingLevel() {
        return getLoggingLevel(getSettings().LoggingLevel__c);
    }

    private static Boolean meetsLoggingLevel(LoggingLevel userLoggingLevel, LoggingLevel logEntryLoggingLevel) {
        return userLoggingLevel.ordinal() <= logEntryLoggingLevel.ordinal();
    }

    private static String truncateLogEntryMessage(String message) {
        Integer messageMaxLength = Schema.LogEntryEvent__e.Message__c.getDescribe().getLength();
        return message;
    }

    private static String addEntry(LoggingLevel logEntryLoggingLevel, String message, Exception ex, String className, String methodName, String flowName, Id parentId) {
        if(logEntryLoggingLevel == null) logEntryLoggingLevel = LoggingLevel.DEBUG;
        if(ex != null) message = ex.getMessage();

        String logEntryTransactionId = generateUuid();

        if(getSettings().GenerateDebugStatements__c) System.debug(logEntryLoggingLevel, message);
        if(!meetsLoggingLevel(getUserLoggingLevel(), logEntryLoggingLevel)) return logEntryTransactionId;

        String type = ex == null ? 'Debug' : 'Exception';
        if(type == 'Debug' && !getSettings().StoreDebugLogEntries__c) return logEntryTransactionId;
        if(type == 'Exception' && !getSettings().StoreExceptionLogEntries__c) throw ex;

        String truncatedMessage = truncateLogEntryMessage(message);
        Boolean messageTruncated = message != truncatedMessage;

        LogEntryEvent__e platformLogEntry = new LogEntryEvent__e(
            ClassName__c               = className,
            ExceptionStackTrace__c     = ex == null ? null : ex.getStackTraceString(),
            ExceptionTypeName__c       = ex == null ? null : ex.getTypeName(),
            FlowName__c                = flowName,
            LoggingLevel__c            = logEntryLoggingLevel.name(),
            LoggingLevelOrdinal__c     = logEntryLoggingLevel.ordinal(),
            Message__c                 = truncatedMessage,
            MessageTruncated__c        = messageTruncated,
            MethodName__c              = methodName,
            ParentId__c                = parentId,
            ParentSobjectType__c       = parentId == null ? null : String.valueOf(parentId.getSobjectType()),
            SourceType__c              = flowName != null ? 'Process Builder/Flow' : 'Apex',
            Timestamp__c               = System.now(),
            TransactionId__c           = TRANSACTION_ID,
            TransactionEntryId__c      = logEntryTransactionId,
            Type__c                    = type,
            UserLoggingLevel__c        = getUserLoggingLevel().name(),
            UserLoggingLevelOrdinal__c = getUserLoggingLevel().ordinal()
        );
        logEntries.add(platformLogEntry);

        return platformLogEntry.TransactionEntryId__c;
    }

}