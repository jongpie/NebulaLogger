public without sharing virtual class LogEntryBuilder {

    private static final String API_VERSION           = getApiVersion();
    private static final String ENTRY_TYPE_DIAGNOSTIC = 'Diagnostic';
    private static final String ENTRY_TYPE_EXCEPTION  = 'Exception';
    private static final String ORIGIN_TYPE_APEX      = 'Apex';
    private static final String ORIGIN_TYPE_COMPONENT = 'Component';
    private static final String ORIGIN_TYPE_FLOW      = 'Flow';

    private final LogEntryEvent__e logEntryEvent;

    private Boolean userSessionDetailsAreSet = false;

    public LogEntryBuilder(LoggingLevel loggingLevel) {
        this.logEntryEvent = new LogEntryEvent__e(
            ApiVersion__c                     = API_VERSION,
            ContextIsTriggerExecuting__c      = Trigger.isExecuting,
            ContextIsVisualforce__c           = ApexPages.currentPage() != null,
            ContextTriggerOperationType__c    = Trigger.operationType == null ? null : Trigger.operationType.name(),
            ContextTriggerSObjectType__c      = Trigger.new == null ? null : String.valueOf(Trigger.new.getSObjectType()),
            ContextVisualforcePage__c         = getVisualforcePageName(),
            LimitsAggregateQueriesUsed__c     = Limits.getAggregateQueries(),
            LimitsAsyncCallsUsed__c           = Limits.getAsyncCalls(),
            LimitsCalloutsUsed__c             = Limits.getCallouts(),
            LimitsCpuTimeUsed__c              = Limits.getCpuTime(),
            LimitsDmlRowsUsed__c              = Limits.getDmlRows(),
            LimitsDmlStatementsUsed__c        = Limits.getDmlStatements(),
            LimitsEmailInvocationsUsed__c     = Limits.getEmailInvocations(),
            LimitsFutureCallsUsed__c          = Limits.getFutureCalls(),
            LimitsHeapSizeUsed__c             = Limits.getHeapSize(),
            LimitsMobilePushApexCallsUsed__c  = Limits.getMobilePushApexCalls(),
            LimitsQueueableJobsUsed__c        = Limits.getQueueableJobs(),
            LimitsSoqlQueriesUsed__c          = Limits.getQueries(),
            LimitsSoqlQueryLocatorRowsUsed__c = Limits.getQueryLocatorRows(),
            LimitsSoqlQueryRowsUsed__c        = Limits.getQueryRows(),
            LimitsSoslSearchesUsed__c         = Limits.getSoslQueries(),
            LoggingLevel__c                   = loggingLevel.NAME(),
            LoggingLevelOrdinal__c            = loggingLevel.ORDINAL(),
            OriginLocation__c                 = getOriginLocation(),
            OriginType__c                     = ORIGIN_TYPE_APEX,
            SystemModeIsApexRest__c           = RestContext.request != null,
            SystemModeIsBatch__c              = System.isBatch(),
            SystemModeIsFuture__c             = System.isFuture(),
            SystemModeIsQueueable__c          = System.isQueueable(),
            SystemModeIsScheduledJob__c       = System.isScheduled(),
            Timestamp__c                      = System.now(),
            TransactionId__c                  = Logger.getTransactionId(),
            Type__c                           = ENTRY_TYPE_DIAGNOSTIC
        );
    }

    public LogEntryBuilder parseFlowLogEntry(FlowLogEntry flowLogEntry) {
        this.logEntryEvent.LoggingLevel__c    = flowLogEntry.loggingLevelName;
        this.logEntryEvent.OriginLocation__c  = flowLogEntry.flowName;
        this.logEntryEvent.OriginType__c      = ORIGIN_TYPE_FLOW;
        this.logEntryEvent.RelatedRecordId__c = flowLogEntry.recordId;
        this.logEntryEvent.Timestamp__c       = flowLogEntry.timestamp;

        return this.setMessage(flowLogEntry.message);
    }

    public LogEntryBuilder parseComponentLogEntry(ComponentLogEntry componentLogEntry) {
        this.logEntryEvent.ContextIsLightningComponent__c   = componentLogEntry.componentName != null;
        this.logEntryEvent.ContextLightningComponentName__c = componentLogEntry.componentName;
        this.logEntryEvent.OriginLocation__c                = componentLogEntry.originLocation;
        this.logEntryEvent.OriginType__c                    = ORIGIN_TYPE_COMPONENT;
        this.logEntryEvent.Timestamp__c                     = componentLogEntry.timestamp;

        return this.setMessage(componentLogEntry.message).setTopics(componentLogEntry.topics);
    }

    public LogEntryBuilder setMessage(String message) {
        String truncatedMessage = truncateFieldValue(Schema.LogEntryEvent__e.Message__c, message);

        this.logEntryEvent.Message__c          = truncatedMessage;
        this.logEntryEvent.MessageTruncated__c = message != truncatedMessage;

        return this;
    }

    public LogEntryBuilder setExceptionDetails(Exception apexException) {
        return this.setExceptionDetails(apexException.getTypeName(), apexException.getStackTraceString());
    }

    public LogEntryBuilder setExceptionDetails(String exceptionType, String exceptionStackTrace) {
        this.logEntryEvent.ExceptionType__c       = exceptionType;
        this.logEntryEvent.ExceptionStackTrace__c = exceptionStackTrace;
        this.logEntryEvent.Type__c                = ENTRY_TYPE_EXCEPTION;

        return this;
    }

    public LogEntryBuilder setRecordId(SObject record) {
        return this.setRecordId(record.Id);
    }

    public LogEntryBuilder setRecordId(Id recordId) {
        this.logEntryEvent.RelatedRecordId__c = recordId;
        return this;
    }

    public LogEntryBuilder setTopics(List<String>topics) {
        this.logEntryEvent.Topics__c = getTopicsString(topics);
        return this;
    }

    public LogEntryEvent__e getLogEntryEvent() {
        // Lazy-loading of setting user-session details to help minimize Apex heap size usage
        if(!this.userSessionDetailsAreSet) this.setUserSessionDetails();

        return this.logEntryEvent;
    }

    private static String getApiVersion() {
        String userJson = Json.serialize(new User(Id = UserInfo.getUserId()));
        return userJson.substringAfter('/data/').substringBefore('.0/sobjects/');
    }

    private String getOriginLocation() {
        String originLocation;
        for(String currentStackTraceLine : new DmlException().getStackTraceString().split('\n')) {
            if(currentStackTraceLine.startsWith('Class.LogEntryBuilder.')) continue;
            if(currentStackTraceLine.startsWith('Class.Logger.')) continue;

            originLocation = currentStackTraceLine.substringBefore(':');
            if(originLocation.startsWith('Class.')) {
                originLocation = originLocation.substringAfter('Class.');
            }
            break;
        }

        return originLocation;
    }

    private static String getVisualforcePageName() {
        String visualforcePageName = ApexPages.currentPage() == null ? null : ApexPages.currentPage().getUrl();
        if(visualforcePageName != null && visualforcePageName.contains('?')) visualforcePageName = visualforcePageName.substringBetween('apex/', '?');
        else if(visualforcePageName != null) visualforcePageName = visualforcePageName.substringAfter('apex/');

        return visualforcePageName;
    }

    private void setUserSessionDetails() {
        User currentUser               = [SELECT Id, Profile.Name, UserRole.Name FROM User WHERE Id = :UserInfo.getUserId()];
        Map<String, String> sessionMap = Test.isRunningTest() ? null : Auth.SessionManagement.getCurrentSession();
        LoggingLevel userLoggingLevel  = Logger.getLoggingLevel(LoggerSettings__c.getInstance().LoggingLevel__c);

        this.logEntryEvent.LimitsAggregateQueriesMax__c      = Limits.getLimitAggregateQueries();
        this.logEntryEvent.LimitsAsyncCallsMax__c            = Limits.getLimitAsyncCalls();
        this.logEntryEvent.LimitsCalloutsMax__c              = Limits.getLimitCallouts();
        this.logEntryEvent.LimitsCpuTimeMax__c               = Limits.getLimitCpuTime();
        this.logEntryEvent.LimitsDmlRowsMax__c               = Limits.getLimitDmlRows();
        this.logEntryEvent.LimitsDmlStatementsMax__c         = Limits.getLimitDmlStatements();
        this.logEntryEvent.LimitsEmailInvocationsMax__c      = Limits.getLimitEmailInvocations();
        this.logEntryEvent.LimitsFutureCallsMax__c           = Limits.getLimitFutureCalls();
        this.logEntryEvent.LimitsHeapSizeMax__c              = Limits.getLimitHeapSize();
        this.logEntryEvent.LimitsMobilePushApexCallsMax__c   = Limits.getLimitMobilePushApexCalls();
        this.logEntryEvent.LimitsQueueableJobsMax__c         = Limits.getLimitQueueableJobs();
        this.logEntryEvent.LimitsSoqlQueriesMax__c           = Limits.getLimitQueries();
        this.logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c  = Limits.getLimitQueryLocatorRows();
        this.logEntryEvent.LimitsSoqlQueryRowsMax__c         = Limits.getLimitQueryRows();
        this.logEntryEvent.LimitsSoslSearchesMax__c          = Limits.getLimitSoslQueries();
        this.logEntryEvent.Locale__c                         = UserInfo.getLocale();
        this.logEntryEvent.LoginDomain__c                    = sessionMap == null ? null : sessionMap.get('LoginDomain');
        this.logEntryEvent.LoginHistoryId__c                 = sessionMap == null ? null : sessionMap.get('LoginHistoryId');
        this.logEntryEvent.LoginType__c                      = sessionMap == null ? null : sessionMap.get('LoginType');
        this.logEntryEvent.LogoutUrl__c                      = sessionMap == null ? null : sessionMap.get('LogoutUrl');
        this.logEntryEvent.ProfileId__c                      = UserInfo.getProfileId();
        this.logEntryEvent.ProfileName__c                    = currentUser.Profile.Name;
        this.logEntryEvent.SessionId__c                      = sessionMap == null ? null : sessionMap.get('SessionId');
        this.logEntryEvent.SessionSecurityLevel__c           = sessionMap == null ? null : sessionMap.get('SessionSecurityLevel');
        this.logEntryEvent.SessionType__c                    = sessionMap == null ? null : sessionMap.get('SessionType');
        this.logEntryEvent.SourceIp__c                       = sessionMap == null ? null : sessionMap.get('SourceIp');
        this.logEntryEvent.TimeZoneId__c                     = UserInfo.getTimeZone().getId();
        this.logEntryEvent.TimeZoneName__c                   = UserInfo.getTimeZone().getDisplayName();
        this.logEntryEvent.UserLoggingLevel__c               = userLoggingLevel.name();
        this.logEntryEvent.UserLoggingLevelOrdinal__c        = userLoggingLevel.ordinal();
        this.logEntryEvent.UserRoleId__c                     = UserInfo.getUserRoleId();
        this.logEntryEvent.UserRoleName__c                   = currentUser.UserRole == null ? null : currentUser.UserRole.Name;
        this.logEntryEvent.UserType__c                       = UserInfo.getUserType();

        if(this.logEntryEvent.SessionType__c == 'UI') this.logEntryEvent.ContextThemeDisplayed__c= UserInfo.getUiThemeDisplayed();
    }

    // Private static methods
    private static String getTopicsString(List<String> topics) {
        if(topics == null || topics.isEmpty()) return null;

        String topicsString = String.escapeSingleQuotes(String.join(topics, ','));
        return truncateFieldValue(Schema.LogEntryEvent__e.Topics__c, topicsString);
    }

    private static String truncateFieldValue(Schema.SObjectField field, String value) {
        Integer fieldMaxLength = field.getDescribe().getLength();
        if(String.isEmpty(value)) return value;
        else if(value.length() <= fieldMaxLength) return value;
        else return value.left(fieldMaxLength);
    }

}