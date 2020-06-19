/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class Logger {

    private static final String TRANSACTION_ID              = new Uuid().getValue();
    private static final List<LogEntryEvent__e> LOG_ENTRIES = new List<LogEntryEvent__e>();

    private static Boolean suspendSaving = false;

    public static String getTransactionId() {
        return TRANSACTION_ID;
    }

    public static void suspendSaving() {
        suspendSaving = true;
    }

    public static void resumeSaving() {
        suspendSaving = false;
    }

    public static void flushBuffer() {
        LOG_ENTRIES.clear();
    }

    public static String addDebugEntry(String message) {
        return addDebugEntry(null, message);
    }

    public static String addDebugEntry(LoggingLevel loggingLevel, String message) {
        return addDebugEntry(loggingLevel, message, null);
    }

    public static String addDebugEntry(LoggingLevel loggingLevel, String message, List<String> topics) {
        return addEntry(loggingLevel, null, message, null, 'Apex', getStackTraceString(), topics, null);
    }

    public static String addExceptionEntry(Exception ex) {
        return addExceptionEntry(ex, null);
    }

    public static String addExceptionEntry(Exception ex, List<String> topics) {
        return addEntry(LoggingLevel.ERROR, null, ex.getMessage(), ex, 'Apex', getStackTraceString(), topics, null);
    }

    public static String addRecordDebugEntry(SObject record, String message) {
        return addRecordDebugEntry(null, record, message);
    }

    public static String addRecordDebugEntry(LoggingLevel loggingLevel, SObject record, String message) {
        return addRecordDebugEntry(loggingLevel, record, message, null);
    }

    public static String addRecordDebugEntry(LoggingLevel loggingLevel, SObject record, String message, List<String> topics) {
        return addEntry(loggingLevel, record, message, null, 'Apex', getStackTraceString(), topics, null);
    }

    public static String addRecordExceptionEntry(SObject record, Exception ex) {
        return addRecordExceptionEntry(record, ex, null);
    }

    public static String addRecordExceptionEntry(SObject record, Exception ex, List<String> topics) {
        return addEntry(LoggingLevel.ERROR, record, ex.getMessage(), ex, 'Apex', getStackTraceString(), topics, null);
    }

    public static void addFlowEntries(List<FlowLogEntry> flowLogEntries) {
        Boolean saveLog = false;
        for(FlowLogEntry flowLogEntry : flowLogEntries) {
            LoggingLevel loggingLevel;
            if(!String.isBlank(flowLogEntry.LoggingLevelName)) loggingLevel = getLoggingLevel(flowLogEntry.LoggingLevelName);

            if(flowLogEntry.saveLog) saveLog = true;

            SObject record = flowLogEntry.recordId == null ? null : flowLogEntry.recordId.getSObjectType().newSObject(flowLogEntry.recordId);

            addEntry(loggingLevel, record, flowLogEntry.message, null, 'Process Builder/Flow', flowLogEntry.flowName, flowLogEntry.topics, null);
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

            addEntry(logLevel, null, logEntry.message, null, 'Lightning Component', logEntry.originLocation, logEntry.topics, logEntry);
        }
        saveLog();
    }

    @InvocableMethod(label='Save Log' description='Saves any log entries that have been generated')
    public static void saveLog() {
        saveLog(false);
    }

    public static String saveLog(Boolean saveLogViaRestApi) {
        if(LOG_ENTRIES.isEmpty()) return getTransactionId();

        String originLocation = 'Logger.saveLog';
        if(suspendSaving) {
            String suspendSavingLogMessage = 'Logging suspended, ignoring call to saveLog()';

            addEntry(LoggingLevel.FINEST, null, suspendSavingLogMessage, null, 'Apex', originLocation, null, null);

            return getTransactionId();
        }

        String savingLogMessage = 'Saving ' + LOG_ENTRIES.size() + ' log entries';
        if(saveLogViaRestApi) savingLogMessage += ' via REST API';

        addEntry(LoggingLevel.FINEST, null, savingLogMessage, null, 'Apex', originLocation, null, null);

        if(saveLogViaRestApi) RestApi.insertRecords(LOG_ENTRIES);
        else EventBus.publish(LOG_ENTRIES);

        LOG_ENTRIES.clear();

        return getTransactionId();
    }

    private static LoggerSettings__c getSettings() {
        return LoggerSettings__c.getInstance();
    }

    private static String getStackTraceString() {
        String stackTraceString;
        for(String currentStackTraceLine : new DmlException().getStackTraceString().split('\n')) {
            if(currentStackTraceLine.contains(Logger.class.getName())) continue;

            stackTraceString = currentStackTraceLine.substringBefore(':');
            if(stackTraceString.startsWith('Class.')) {
                stackTraceString = stackTraceString.substringAfter('Class.');
            }
            break;
        }

        return stackTraceString;
    }

    private static LoggingLevel getLoggingLevel(String loggingLevelName) {
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
            when else     {
                final LoggingLevel DEFAULT_LEVEL = LoggingLevel.DEBUG;

                String originLocation             = 'Logger.getLoggingLevel';
                String unknownLoggingLevelMessage = 'Unknown logging level ' + loggingLevelName + ', using ' + DEFAULT_LEVEL.name();

                addEntry(LoggingLevel.FINEST, null, unknownLoggingLevelMessage, null, 'Apex', originLocation, null, null);

                return DEFAULT_LEVEL;
            }
        }
    }

    private static LoggingLevel getUserLoggingLevel() {
        return getLoggingLevel(getSettings().LoggingLevel__c);
    }

    private static Boolean meetsUserLoggingLevel(LoggingLevel userLoggingLevel, LoggingLevel logEntryLoggingLevel) {
        return userLoggingLevel.ordinal() <= logEntryLoggingLevel.ordinal();
    }

    private static String truncateFieldValue(Schema.SObjectField field, String value) {
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

    private static String addEntry(LoggingLevel logEntryLoggingLevel, SObject record, String message, Exception ex, String originType, String originLocation, List<String> topics, LightningLogEntry lightningLogEntry) {
        Datetime logEntryTimestamp = lightningLogEntry == null ? System.now() : lightningLogEntry.timestamp;

        if(logEntryLoggingLevel == null) logEntryLoggingLevel = LoggingLevel.DEBUG;
        if(ex != null) message = ex.getMessage();
        if(lightningLogEntry != null && lightningLogEntry.error != null) message = lightningLogEntry.error.message;

        String logEntryTransactionId = new Uuid().getValue();

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
            ContextTriggerSObjectType__c      = Trigger.new == null ? null : String.valueOf(Trigger.new.getSObjectType()),
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
            OriginLocation__c                 = truncateFieldValue(Schema.LogEntryEvent__e.OriginLocation__c, originLocation),
            OriginType__c                     = originType,
            RelatedRecordId__c                = record != null && record.Id != null ? record.Id : null,
            Timestamp__c                      = logEntryTimestamp,
            Topics__c                         = topics == null ? null : String.escapeSingleQuotes(String.join(topics, ',')),
            TransactionEntryId__c             = logEntryTransactionId,
            TransactionId__c                  = TRANSACTION_ID,
            Type__c                           = type,
            UserLoggingLevel__c               = getUserLoggingLevel().name(),
            UserLoggingLevelOrdinal__c        = getUserLoggingLevel().ordinal()
        );
        LOG_ENTRIES.add(platformLogEntry);

        if(ex != null && getSettings().AutoSaveExceptionEntries__c) saveLog();

        return platformLogEntry.TransactionEntryId__c;
    }

}