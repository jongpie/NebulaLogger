/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
global without sharing class LogEntryBuilder {
    private static final String API_VERSION = getApiVersion();
    private static final String ENTRY_TYPE_DIAGNOSTIC = 'Diagnostic';
    private static final String ENTRY_TYPE_EXCEPTION = 'Exception';
    private static final String NAMESPACE_PREFIX = getNamespacePrefix();
    private static final String ORIGIN_TYPE_APEX = 'Apex';
    private static final String ORIGIN_TYPE_COMPONENT = 'Component';
    private static final String ORIGIN_TYPE_FLOW = 'Flow';

    private final LogEntryEvent__e logEntryEvent;

    private Boolean shouldSave;
    private Boolean userSessionDetailsAreSet = false;

    global LogEntryBuilder(LoggingLevel loggingLevel) {
        this.shouldSave = Logger.isEnabled(loggingLevel);
        if (!this.shouldSave) {
            return;
        }

        DmlException stackTraceException = new DmlException();

        this.logEntryEvent = new LogEntryEvent__e(
            ApiVersion__c = API_VERSION,
            ContextIsTriggerExecuting__c = Trigger.isExecuting,
            ContextTriggerOperationType__c = Trigger.operationType == null ? null : Trigger.operationType.name(),
            ContextTriggerSObjectType__c = Trigger.new == null ? null : String.valueOf(Trigger.new.getSObjectType()),
            LimitsAggregateQueriesUsed__c = Limits.getAggregateQueries(),
            LimitsAsyncCallsUsed__c = Limits.getAsyncCalls(),
            LimitsCalloutsUsed__c = Limits.getCallouts(),
            LimitsCpuTimeUsed__c = Limits.getCpuTime(),
            LimitsDmlRowsUsed__c = Limits.getDmlRows(),
            LimitsDmlStatementsUsed__c = Limits.getDmlStatements(),
            LimitsEmailInvocationsUsed__c = Limits.getEmailInvocations(),
            LimitsFutureCallsUsed__c = Limits.getFutureCalls(),
            LimitsHeapSizeUsed__c = Limits.getHeapSize(),
            LimitsMobilePushApexCallsUsed__c = Limits.getMobilePushApexCalls(),
            LimitsQueueableJobsUsed__c = Limits.getQueueableJobs(),
            LimitsSoqlQueriesUsed__c = Limits.getQueries(),
            LimitsSoqlQueryLocatorRowsUsed__c = Limits.getQueryLocatorRows(),
            LimitsSoqlQueryRowsUsed__c = Limits.getQueryRows(),
            LimitsSoslSearchesUsed__c = Limits.getSoslQueries(),
            LoggingLevel__c = loggingLevel.NAME(),
            LoggingLevelOrdinal__c = loggingLevel.ORDINAL(),
            OriginType__c = ORIGIN_TYPE_APEX,
            ParentLogTransactionId__c = Logger.getParentLogTransactionId(),
            SystemModeIsApexRest__c = RestContext.request != null,
            SystemModeIsBatch__c = System.isBatch(),
            SystemModeIsFuture__c = System.isFuture(),
            SystemModeIsQueueable__c = System.isQueueable(),
            SystemModeIsScheduledJob__c = System.isScheduled(),
            Timestamp__c = System.now(),
            TransactionId__c = Logger.getTransactionId(),
            Type__c = ENTRY_TYPE_DIAGNOSTIC
        );

        this.parseStackTrace(stackTraceException.getStackTraceString());
    }

    global LogEntryBuilder setMessage(String message) {
        if (!this.shouldSave) {
            return this;
        }

        String truncatedMessage = truncateFieldValue(Schema.LogEntryEvent__e.Message__c, message);

        this.logEntryEvent.Message__c = truncatedMessage;
        this.logEntryEvent.MessageTruncated__c = message != truncatedMessage;

        return this;
    }

    global LogEntryBuilder setMessage(LogMessage logMessage) {
        if (!this.shouldSave) {
            return this;
        }

        return this.setMessage(logMessage.getMessage());
    }

    global LogEntryBuilder setExceptionDetails(Exception apexException) {
        if (!this.shouldSave) {
            return this;
        }

        this.logEntryEvent.ExceptionMessage__c = apexException.getMessage();
        this.logEntryEvent.ExceptionType__c = apexException.getTypeName();
        this.logEntryEvent.Type__c = ENTRY_TYPE_EXCEPTION;

        // Stack traces are not returned for managed packages
        if (getNamespacePrefix() == null) {
            this.logEntryEvent.ExceptionStackTrace__c = apexException.getStackTraceString();
        }

        if (LoggerSettings__c.getInstance().AutoSaveExceptionEntries__c) {
            Logger.saveLog();
        }

        return this;
    }

    global LogEntryBuilder setRecordId(SObject record) {
        if (!this.shouldSave) {
            return this;
        }

        String truncatedRecordJson = truncateFieldValue(
            Schema.LogEntryEvent__e.RelatedRecordJson__c,
            Json.serializePretty(record)
        );
        this.logEntryEvent.RelatedRecordJson__c = truncatedRecordJson;

        return this.setRecordId(record.Id);
    }

    global LogEntryBuilder setRecordId(Id recordId) {
        if (!this.shouldSave) {
            return this;
        }

        this.logEntryEvent.RelatedRecordId__c = recordId;
        return this;
    }

    global LogEntryBuilder setTopics(List<String> topics) {
        if (!this.shouldSave) {
            return this;
        }

        this.logEntryEvent.Topics__c = getTopicsString(topics);
        return this;
    }

    global LogEntryBuilder parseStackTrace(String stackTraceString) {
        if (!this.shouldSave) {
            return this;
        }

        // Stack traces are not returned for managed packages
        if (getNamespacePrefix() != null) {
            return this;
        }

        List<String> stackTraceLines = new List<String>();
        String originLocation;
        for (String currentStackTraceLine : stackTraceString.split('\n')) {
            // Don't include the logging system's classes in the stack trace
            List<String> ignoredClasses = new List<String>{
                Logger.class.getName(),
                LogMessage.class.getName(),
                LogEntryBuilder.class.getName()
            };
            for (String ignoredClass : ignoredClasses) {
                if (currentStackTraceLine.contains('.' + ignoredClass + '.')) {
                    continue;
                }
            }

            // Set the stack trace & origin location
            stackTraceLines.add(currentStackTraceLine);
            originLocation = currentStackTraceLine.substringBefore(':');
            if (originLocation.startsWith('Class.')) {
                originLocation = originLocation.substringAfter('Class.');
            }
        }

        this.logEntryEvent.OriginLocation__c = originLocation;
        this.logEntryEvent.StackTrace__c = String.join(stackTraceLines, '\n');

        return this;
    }

    global LogEntryBuilder alwaysSave() {
        this.shouldSave = true;
        return this;
    }

    global Boolean shouldSave() {
        return this.shouldSave;
    }

    global LogEntryEvent__e getLogEntryEvent() {
        // Lazy-loading of setting user-session details to help minimize Apex heap size usage
        if (!this.userSessionDetailsAreSet) {
            this.setUserSessionDetails();
        }

        return this.logEntryEvent;
    }

    global void setUserSessionDetails() {
        if (!this.shouldSave) {
            return;
        }

        Map<String, String> sessionMap = this.getSessionMap();
        LoggingLevel userLoggingLevel = Logger.getLoggingLevel(LoggerSettings__c.getInstance().LoggingLevel__c);

        this.logEntryEvent.ContextIsVisualforce__c = ApexPages.currentPage() != null;
        this.logEntryEvent.ContextVisualforcePage__c = getVisualforcePageName();
        this.logEntryEvent.LimitsAggregateQueriesMax__c = Limits.getLimitAggregateQueries();
        this.logEntryEvent.LimitsAsyncCallsMax__c = Limits.getLimitAsyncCalls();
        this.logEntryEvent.LimitsCalloutsMax__c = Limits.getLimitCallouts();
        this.logEntryEvent.LimitsCpuTimeMax__c = Limits.getLimitCpuTime();
        this.logEntryEvent.LimitsDmlRowsMax__c = Limits.getLimitDmlRows();
        this.logEntryEvent.LimitsDmlStatementsMax__c = Limits.getLimitDmlStatements();
        this.logEntryEvent.LimitsEmailInvocationsMax__c = Limits.getLimitEmailInvocations();
        this.logEntryEvent.LimitsFutureCallsMax__c = Limits.getLimitFutureCalls();
        this.logEntryEvent.LimitsHeapSizeMax__c = Limits.getLimitHeapSize();
        this.logEntryEvent.LimitsMobilePushApexCallsMax__c = Limits.getLimitMobilePushApexCalls();
        this.logEntryEvent.LimitsQueueableJobsMax__c = Limits.getLimitQueueableJobs();
        this.logEntryEvent.LimitsSoqlQueriesMax__c = Limits.getLimitQueries();
        this.logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c = Limits.getLimitQueryLocatorRows();
        this.logEntryEvent.LimitsSoqlQueryRowsMax__c = Limits.getLimitQueryRows();
        this.logEntryEvent.LimitsSoslSearchesMax__c = Limits.getLimitSoslQueries();
        this.logEntryEvent.Locale__c = UserInfo.getLocale();
        this.logEntryEvent.NetworkId__c = Network.getNetworkId();
        this.logEntryEvent.LoginDomain__c = sessionMap?.get('LoginDomain');
        this.logEntryEvent.LoginHistoryId__c = sessionMap?.get('LoginHistoryId');
        this.logEntryEvent.LoginType__c = sessionMap?.get('LoginType');
        this.logEntryEvent.LogoutUrl__c = sessionMap?.get('LogoutUrl');
        this.logEntryEvent.ProfileId__c = UserInfo.getProfileId();
        this.logEntryEvent.SessionId__c = sessionMap?.get('SessionId');
        this.logEntryEvent.SessionSecurityLevel__c = sessionMap?.get('SessionSecurityLevel');
        this.logEntryEvent.SessionType__c = sessionMap?.get('SessionType');
        this.logEntryEvent.SourceIp__c = sessionMap?.get('SourceIp');
        this.logEntryEvent.TimeZoneId__c = UserInfo.getTimeZone().getId();
        this.logEntryEvent.TimeZoneName__c = UserInfo.getTimeZone().getDisplayName();
        this.logEntryEvent.UserLoggingLevel__c = userLoggingLevel.name();
        this.logEntryEvent.UserLoggingLevelOrdinal__c = userLoggingLevel.ordinal();
        this.logEntryEvent.UserRoleId__c = UserInfo.getUserRoleId();
        this.logEntryEvent.UserType__c = UserInfo.getUserType();

        if (this.logEntryEvent.SessionType__c != 'Oauth2') {
            this.logEntryEvent.ContextThemeDisplayed__c = UserInfo.getUiThemeDisplayed();
        }
    }

    private Map<String, String> getSessionMap() {
        // Scheduled jobs, batch jobs, invocables, future methods and queueables are ALL
        // run by the Automated Process user - attempting to access Auth.SessionManagement
        // methods as that user throws an UNCATCHABLE error. Let's sidestep that.
        if (
            Test.isRunningTest() ||
            // no System class method for this one, Winter '21 to the rescue!
            Logger.getCurrentQuiddity() == Quiddity.INVOCABLE_ACTION ||
            System.isBatch() ||
            System.isQueueable() ||
            System.isScheduled() ||
            System.isFuture()
        ) {
            return new Map<String, String>{ 'SessionId' => UserInfo.getSessionId() };
        }
        return Auth.SessionManagement.getCurrentSession();
    }

    private static String getApiVersion() {
        String userJson = Json.serialize(new User(Id = UserInfo.getUserId()));
        return userJson.substringAfter('/data/').substringBefore('.0/sobjects/');
    }

    private static String getVisualforcePageName() {
        String visualforcePageName = ApexPages.currentPage() == null ? null : ApexPages.currentPage().getUrl();
        if (visualforcePageName != null && visualforcePageName.contains('?')) {
            visualforcePageName = visualforcePageName.substringBetween('apex/', '?');
        } else if (visualforcePageName != null) {
            visualforcePageName = visualforcePageName.substringAfter('apex/');
        }

        return visualforcePageName;
    }

    // Private static methods
    private static String getNamespacePrefix() {
        String namespacePrefix = null;

        String className = LogEntryBuilder.class.getName().substringBefore(':');
        if (className.contains('.')) {
            namespacePrefix = className.substringBefore('.');
        }
        return namespacePrefix;
    }

    private static String getTopicsString(List<String> topics) {
        if (topics == null || topics.isEmpty()) {
            return null;
        }

        String topicsString = String.escapeSingleQuotes(String.join(topics, ','));
        return truncateFieldValue(Schema.LogEntryEvent__e.Topics__c, topicsString);
    }

    private static String truncateFieldValue(Schema.SObjectField field, String value) {
        Integer fieldMaxLength = field.getDescribe().getLength();
        if (String.isEmpty(value)) {
            return value;
        } else if (value.length() <= fieldMaxLength) {
            return value;
        }

        return value.left(fieldMaxLength);
    }
}
