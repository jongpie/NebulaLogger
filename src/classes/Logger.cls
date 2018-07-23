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

    public static String addDebugEntry(String message, String originLocation) {
        return addDebugEntry(null, message, originLocation);
    }

    public static String addDebugEntry(LoggingLevel loggingLevel, String message, String originLocation) {
        return addDebugEntry(loggingLevel, message, originLocation, null);
    }

    public static String addDebugEntry(LoggingLevel loggingLevel, String message, String originLocation, List<String> topics) {
        return addEntry(loggingLevel, message, null, 'Apex', originLocation, topics, null);
    }

    public static String addExceptionEntry(Exception ex, String originLocation) {
        return addExceptionEntry(ex, originLocation, null);
    }

    public static String addExceptionEntry(Exception ex, String originLocation, List<String> topics) {
        return addEntry(LoggingLevel.ERROR, ex.getMessage(), ex, 'Apex', originLocation, topics, null);
    }

    public static void addFlowEntries(List<FlowLogEntry> flowLogEntries) {
        Boolean saveLog = false;
        for(FlowLogEntry flowLogEntry : flowLogEntries) {
            LoggingLevel loggingLevel;
            if(!String.isBlank(flowLogEntry.LoggingLevelName)) loggingLevel = getLoggingLevel(flowLogEntry.LoggingLevelName);

            if(flowLogEntry.saveLog) saveLog = true;

            addEntry(loggingLevel, flowLogEntry.message, null, 'Process Builder/Flow', flowLogEntry.flowName, flowLogEntry.topics, null);
        }
        if(saveLog) saveLog();
    }

    @AuraEnabled
    public static void saveLightningEntries(String logEntriesJson) {
        List<LightningLogEntry> lightningLogEntries = (List<LightningLogEntry>)Json.deserialize(logEntriesJson, List<LightningLogEntry>.class);
        for(LightningLogEntry logEntry : lightningLogEntries) {
            LoggingLevel logLevel;
            if(!String.isBlank(logEntry.loggingLevelName)) logLevel = getLoggingLevel(logEntry.loggingLevelName);
            if(logEntry.error != null) logLevel = LoggingLevel.ERROR;

            addEntry(logLevel, logEntry.message, null, 'Lightning Component', logEntry.originLocation, logEntry.topics, logEntry);
        }
        saveLog();
    }

    public static LoggingLevel getLoggingLevel(String loggingLevelName) {
        if(loggingLevelName != null) loggingLevelName = loggingLevelName.toUpperCase();

        switch on loggingLevelName {
            when 'NONE'   { return LoggingLevel.NONE;   }
            when 'ERROR'  { return LoggingLevel.ERROR;  }
            when 'WARN'   { return LoggingLevel.WARN;   }
            when 'INFO'   { return LoggingLevel.INFO;   }
            when 'DEBUG'  { return LoggingLevel.DEBUG;  }
            when 'FINE'   { return LoggingLevel.FINE;   }
            when 'FINER'  { return LoggingLevel.FINER;  }
            when 'FINEST' { return LoggingLevel.FINEST; }
            when else     { return LoggingLevel.NONE;   }
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

    private static Boolean meetsUserLoggingLevel(LoggingLevel userLoggingLevel, LoggingLevel logEntryLoggingLevel) {
        return userLoggingLevel.ordinal() <= logEntryLoggingLevel.ordinal();
    }

    private static String truncateFieldValue(Schema.SobjectField field, String value) {
        Integer fieldMaxLength = field.getDescribe().getLength();
        if(String.isEmpty(value)) return value;
        else if(value.length() <= fieldMaxLength) return value;
        else return value.left(fieldMaxLength);
    }

    private static String getExceptionStackTrace(Exception ex, LightningLogEntry lightningLogEntry) {
        if(ex != null) return ex.getStackTraceString();
        else if(lightningLogEntry != null && lightningLogEntry.error != null) return lightningLogEntry.error.stack;
        else return null;
    }

    private static String getExceptionType(Exception ex, LightningLogEntry lightningLogEntry) {
        if(ex != null) return ex.getTypeName();
        else if(lightningLogEntry != null && lightningLogEntry.error != null) return 'LightningError';
        else return null;
    }

    private static String addEntry(LoggingLevel logEntryLoggingLevel, String message, Exception ex, String originType, String originLocation, List<String> topics, LightningLogEntry lightningLogEntry) {
        Datetime logEntryTimestamp = lightningLogEntry == null ? System.now() : lightningLogEntry.timestamp;

        if(logEntryLoggingLevel == null) logEntryLoggingLevel = LoggingLevel.DEBUG;
        if(ex != null) message = ex.getMessage();
        if(lightningLogEntry != null && lightningLogEntry.error != null) message = lightningLogEntry.error.message;

        String logEntryTransactionId = generateUuid();

        if(getSettings().GenerateDebugStatements__c) System.debug(logEntryLoggingLevel, message);
        if(!meetsUserLoggingLevel(getUserLoggingLevel(), logEntryLoggingLevel)) return logEntryTransactionId;

        String type = 'Debug';
        if(ex != null) type = 'Exception';
        if(lightningLogEntry != null && lightningLogEntry.error != null) type = 'Exception';

        if(type == 'Debug' && !getSettings().StoreDebugLogEntries__c) return logEntryTransactionId;
        if(type == 'Exception' && !getSettings().StoreExceptionLogEntries__c) return logEntryTransactionId;

        String truncatedMessage = truncateFieldValue(Schema.LogEntryEvent__e.Message__c, message);
        Boolean messageTruncated = message != truncatedMessage;

        String visualforcePageName = ApexPages.currentPage() == null ? null : ApexPages.currentPage().getUrl();
        if(visualforcePageName != null && visualforcePageName.contains('?')) visualforcePageName = visualforcePageName.substringBetween('apex/', '?');
        else if(visualforcePageName != null) visualforcePageName = visualforcePageName.substringAfter('apex/');

        LogEntryEvent__e platformLogEntry = new LogEntryEvent__e(
            ContextIsApexRest__c              = RestContext.request != null,
            ContextIsBatch__c                 = System.isBatch(),
            ContextIsFuture__c                = System.isFuture(),
            ContextIsLightningComponent__c    = lightningLogEntry != null,
            ContextIsQueueable__c             = System.isQueueable(),
            ContextIsScheduledJob__c          = System.isScheduled(),
            ContextIsTriggerExecuting__c      = Trigger.isExecuting,
            ContextIsVisualforce__c           = ApexPages.currentPage() != null,
            ContextLightningComponentName__c  = lightningLogEntry == null ? null : lightningLogEntry.componentName,
            ContextThemeDisplayed__c          = UserInfo.getUiThemeDisplayed(),
            ContextTriggerOperationType__c    = Trigger.operationType == null ? null : Trigger.operationType.name(),
            ContextTriggerSobjectType__c      = Trigger.new == null ? null : String.valueOf(Trigger.new.getSobjectType()),
            ContextVisualforcePage__c         = visualforcePageName,
            ExceptionStackTrace__c            = truncateFieldValue(Schema.LogEntryEvent__e.ExceptionStackTrace__c, getExceptionStackTrace(ex, lightningLogEntry)),
            ExceptionType__c                  = truncateFieldValue(Schema.LogEntryEvent__e.ExceptionType__c, getExceptionType(ex, lightningLogEntry)),
            LimitsAggregateQueriesMax__c      = Limits.getLimitAggregateQueries(),
            LimitsAggregateQueriesUsed__c     = Limits.getAggregateQueries(),
            LimitsAsyncCallsMax__c            = Limits.getLimitAsyncCalls(),
            LimitsAsyncCallsUsed__c           = Limits.getAsyncCalls(),
            LimitsCalloutsMax__c              = Limits.getLimitCallouts(),
            LimitsCalloutsUsed__c             = Limits.getCallouts(),
            LimitsCpuTimeMax__c               = Limits.getLimitCpuTime(),
            LimitsCpuTimeUsed__c              = Limits.getCpuTime(),
            LimitsDmlRowsMax__c               = Limits.getLimitDmlRows(),
            LimitsDmlRowsUsed__c              = Limits.getDmlRows(),
            LimitsDmlStatementsMax__c         = Limits.getLimitDmlStatements(),
            LimitsDmlStatementsUsed__c        = Limits.getDmlStatements(),
            LimitsEmailInvocationsMax__c      = Limits.getLimitEmailInvocations(),
            LimitsEmailInvocationsUsed__c     = Limits.getEmailInvocations(),
            LimitsFutureCallsMax__c           = Limits.getLimitFutureCalls(),
            LimitsFutureCallsUsed__c          = Limits.getFutureCalls(),
            LimitsHeapSizeMax__c              = Limits.getLimitHeapSize(),
            LimitsHeapSizeUsed__c             = Limits.getHeapSize(),
            LimitsMobilePushApexCallsMax__c   = Limits.getLimitMobilePushApexCalls(),
            LimitsMobilePushApexCallsUsed__c  = Limits.getMobilePushApexCalls(),
            LimitsQueueableJobsMax__c         = Limits.getLimitQueueableJobs(),
            LimitsQueueableJobsUsed__c        = Limits.getQueueableJobs(),
            LimitsSoqlQueriesMax__c           = Limits.getLimitQueries(),
            LimitsSoqlQueriesUsed__c          = Limits.getQueries(),
            LimitsSoqlQueryLocatorRowsMax__c  = Limits.getLimitQueryLocatorRows(),
            LimitsSoqlQueryLocatorRowsUsed__c = Limits.getQueryLocatorRows(),
            LimitsSoqlQueryRowsMax__c         = Limits.getLimitQueryRows(),
            LimitsSoqlQueryRowsUsed__c        = Limits.getQueryRows(),
            LimitsSoslSearchesMax__c          = Limits.getLimitSoslQueries(),
            LimitsSoslSearchesUsed__c         = Limits.getSoslQueries(),
            LoggingLevel__c                   = logEntryLoggingLevel.name(),
            LoggingLevelOrdinal__c            = logEntryLoggingLevel.ordinal(),
            Message__c                        = truncatedMessage == null ? null : String.escapeSingleQuotes(truncatedMessage),
            MessageTruncated__c               = messageTruncated,
            OriginType__c                     = originType,
            OriginLocation__c                 = truncateFieldValue(Schema.LogEntryEvent__e.OriginLocation__c, originLocation),
            Timestamp__c                      = logEntryTimestamp,
            TransactionId__c                  = TRANSACTION_ID,
            TransactionEntryId__c             = logEntryTransactionId,
            Topics__c                         = topics == null ? null : String.escapeSingleQuotes(String.join(topics, ',')),
            Type__c                           = type,
            UserLoggingLevel__c               = getUserLoggingLevel().name(),
            UserLoggingLevelOrdinal__c        = getUserLoggingLevel().ordinal()
        );
        logEntries.add(platformLogEntry);

        if(ex != null && getSettings().AutoSaveExceptionEntries__c) saveLog();

        return platformLogEntry.TransactionEntryId__c;
    }

}