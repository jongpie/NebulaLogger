/*************************************************************************************************
 * This file is part of the Nebula Logger project, released under the MIT License.                *
 * See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
 *************************************************************************************************/
global with sharing class LogEntryEventBuilder {
    private static final String API_VERSION = getApiVersion();
    private static final String NAMESPACE_PREFIX = getNamespacePrefix();
    private static final String ORIGIN_TYPE_APEX = 'Apex';
    private static final String ORIGIN_TYPE_COMPONENT = 'Component';
    private static final String ORIGIN_TYPE_FLOW = 'Flow';
    private static final Boolean USER_CAN_CREATE_LOG_ENTRY_EVENTS = SObjectType.LogEntryEvent__e.isCreateable();

    private final LogEntryEvent__e logEntryEvent;
    private final LoggingLevel loggingLevel;

    private Boolean shouldSave;
    private Boolean userSessionDetailsAreSet = false;

    public LogEntryEventBuilder(LoggingLevel loggingLevel, Boolean shouldSave) {
        this.loggingLevel = loggingLevel;

        // Verify that the user has create access & has logging enabled
        this.shouldSave = USER_CAN_CREATE_LOG_ENTRY_EVENTS && shouldSave;

        if (this.shouldSave == false) {
            return;
        }

        // TODO alwaysSave() will not have these fields populated due to guard clause above
        // Need to move LogEntryEvent__e to a private method & have another variable (isInitialized?) to track
        // The Limits methods still need to be called ASAP for accuracy (not last-minute like user sessions)
        this.logEntryEvent = new LogEntryEvent__e(
            ApiVersion__c = API_VERSION,
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
            Timestamp__c = System.now(),
            TriggerIsExecuting__c = Trigger.isExecuting,
            TriggerOperationType__c = Trigger.operationType == null ? null : Trigger.operationType.name(),
            TriggerSObjectType__c = Trigger.new == null ? null : String.valueOf(Trigger.new.getSObjectType())
        );

        // TODO add check to see if the class's namespace == the org's namespace
        //if (!hasNamespacePrefix()) {
        DmlException stackTraceException = new DmlException();
        this.parseStackTrace(stackTraceException.getStackTraceString());
        //}
    }

    global LogEntryEventBuilder setMessage(String message) {
        if (!this.shouldSave) {
            return this;
        }

        // When running as unmanaged code, auto-call System.debug
        // System.debug is useless in managed packages, so don't bother when namespaced
        // TODO add check to see if the class's namespace == the org's namespace
        // if (!hasNamespacePrefix()) {
        System.debug(this.loggingLevel, message);
        // }

        String truncatedMessage = truncateFieldValue(Schema.LogEntryEvent__e.Message__c, message);

        this.logEntryEvent.Message__c = truncatedMessage;
        this.logEntryEvent.MessageTruncated__c = message != truncatedMessage;

        return this;
    }

    global LogEntryEventBuilder setMessage(LogMessage logMessage) {
        if (!this.shouldSave) {
            return this;
        }

        return this.setMessage(logMessage.getMessage());
    }

    global LogEntryEventBuilder setExceptionDetails(Exception apexException) {
        if (!this.shouldSave) {
            return this;
        }

        this.logEntryEvent.ExceptionMessage__c = apexException.getMessage();
        this.logEntryEvent.ExceptionType__c = apexException.getTypeName();

        // Stack traces are not returned for managed packages
        if (isValidStackTrace(apexException.getStackTraceString())) {
            this.logEntryEvent.ExceptionStackTrace__c = apexException.getStackTraceString();
        }

        return this;
    }

    global LogEntryEventBuilder setRecordId(SObject record) {
        if (!this.shouldSave) {
            return this;
        }

        String truncatedRecordJson = truncateFieldValue(
            Schema.LogEntryEvent__e.RecordJson__c,
            Json.serializePretty(record)
        );
        this.logEntryEvent.RecordJson__c = truncatedRecordJson;

        return this.setRecordId(record.Id);
    }

    global LogEntryEventBuilder setRecordId(Id recordId) {
        if (!this.shouldSave) {
            return this;
        }

        this.logEntryEvent.RecordId__c = recordId;
        return this;
    }

    global LogEntryEventBuilder setTopics(List<String> topics) {
        if (!this.shouldSave) {
            return this;
        }

        this.logEntryEvent.Topics__c = getTopicsString(topics);
        return this;
    }

    global LogEntryEventBuilder parseStackTrace(String stackTraceString) {
        if (!this.shouldSave) {
            return this;
        }

        // Stack traces are not returned for managed packages
        if (!isValidStackTrace(stackTraceString)) {
            return this;
        }

        List<String> stackTraceLines = new List<String>();
        for (String currentStackTraceLine : stackTraceString.split('\n')) {
            // Don't include the logging system's classes in the stack trace
            List<String> ignoredClasses = new List<String>{
                Logger.class.getName(),
                LogMessage.class.getName(),
                LogEntryEventBuilder.class.getName()
            };

            Boolean ignoreLine = false;
            for (String ignoredClass : ignoredClasses) {
                if (currentStackTraceLine.contains('.' + ignoredClass + '.')) {
                    ignoreLine = true;
                    continue;
                }
            }

            if (ignoreLine) {
                continue;
            }

            stackTraceLines.add(currentStackTraceLine);
        }

        // In a managed package, we can end up with an invalid (unhelpful) stack trace, so only store when valid
        stackTraceString = String.join(stackTraceLines, '\n');
        if (isValidStackTrace(stackTraceString)) {
            String originLocation = stackTraceLines.get(0);
            if (originLocation.contains(':')) {
                originLocation = originLocation.substringBefore(':');
            }
            if (originLocation.startsWith('Class.')) {
                originLocation = originLocation.substringAfter('Class.');
            }

            this.logEntryEvent.OriginLocation__c = originLocation;
            this.logEntryEvent.StackTrace__c = stackTraceString;
        }

        return this;
    }

    public Boolean shouldSave() {
        return this.shouldSave;
    }

    public LogEntryEvent__e getLogEntryEvent() {
        // Lazy-loading of setting user-session details to help minimize Apex heap size usage
        if (!this.userSessionDetailsAreSet) {
            this.setUserSessionDetails();
        }

        return this.logEntryEvent;
    }

    private void setUserSessionDetails() {
        if (!this.shouldSave) {
            return;
        }

        Map<String, String> sessionMap = this.getSessionMap();
        LoggingLevel userLoggingLevel = Logger.getLoggingLevel(LoggerSettings__c.getInstance().LoggingLevel__c);

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
            this.logEntryEvent.ThemeDisplayed__c = UserInfo.getUiThemeDisplayed();
        }
    }

    private Map<String, String> getSessionMap() {
        // Scheduled jobs, batch jobs, invocables, future methods and queueables are ALL
        // run by the Automated Process user - attempting to access Auth.SessionManagement
        // methods as that user throws an UNCATCHABLE error. Let's sidestep that.
        String potentialSession = UserInfo.getSessionId();
        if (String.isBlank(potentialSession) || Test.isRunningTest()) {
            return new Map<String, String>{ 'SessionId' => potentialSession };
        }

        return Auth.SessionManagement.getCurrentSession();
    }

    // Private static methods
    private static String getApiVersion() {
        String userJson = Json.serialize(new User(Id = UserInfo.getUserId()));
        return userJson.substringAfter('/data/').substringBefore('.0/sobjects/');
    }

    // TODO move namespace methods to separate Namespace class (again) if other classes end up needing this info
    private static Boolean hasNamespacePrefix() {
        return String.isNotBlank(NAMESPACE_PREFIX);
    }

    private static String getNamespacePrefix() {
        String className = LogEntryEventBuilder.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

        return namespacePrefix;
    }

    // private static String getPrefixWithDelimiter(String delimiter) {
    //     return String.isBlank(getPrefix()) ? '' : getPrefix() + delimiter;
    // }

    private static String getVisualforcePageName() {
        String visualforcePageName = ApexPages.currentPage() == null ? null : ApexPages.currentPage().getUrl();
        if (visualforcePageName != null && visualforcePageName.contains('?')) {
            visualforcePageName = visualforcePageName.substringBetween('apex/', '?');
        } else if (visualforcePageName != null) {
            visualforcePageName = visualforcePageName.substringAfter('apex/');
        }

        return visualforcePageName;
    }

    private static Boolean isValidStackTrace(String stackTraceString) {
        if (String.isEmpty(stackTraceString)) {
            return false;
        }
        if (stackTraceString == '()') {
            return false;
        }
        if (stackTraceString == '(' + getNamespacePrefix() + ')') {
            return false;
        }

        return true;
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
