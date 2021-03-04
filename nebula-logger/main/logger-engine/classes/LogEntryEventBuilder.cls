//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group logger-engine
 * @description Builder class that generates each LogEntryEvent__c record
 * @see Logger
 */
global with sharing class LogEntryEventBuilder {
    private static final String API_VERSION = getApiVersion();
    private static final List<String> IGNORED_CLASSES = getIgnoredClasses();
    private static final String NAMESPACE_PREFIX = getNamespacePrefix();
    private static final SObject NETWORK_SITE = getNetwork();
    private static final Organization ORGANIZATION = getOrganization();
    private static final String ORIGIN_TYPE_APEX = 'Apex';
    // TODO future enhancement: consider converting strings to enum and add overload for `parseStackTrace(OriginType, String)
    // private static final String ORIGIN_TYPE_COMPONENT = 'Component';
    // private static final String ORIGIN_TYPE_FLOW = 'Flow';
    private static final User USER = getUser();
    private static final Boolean USER_CAN_CREATE_LOG_ENTRY_EVENTS = SObjectType.LogEntryEvent__e.isCreateable();

    private final LogEntryEvent__e logEntryEvent;
    private final LoggingLevel loggingLevel;

    private Boolean detailsAreSet = false;
    private Boolean shouldSave;

    public LogEntryEventBuilder(LoggingLevel loggingLevel, Boolean shouldSave) {
        this.loggingLevel = loggingLevel;

        // Verify that the user has create access
        this.shouldSave = USER_CAN_CREATE_LOG_ENTRY_EVENTS && shouldSave;

        if (this.shouldSave == false) {
            return;
        }

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

    /**
     * Sets the log entry event's message field
     * @param  logMessage The instance of LogMessage to use - LogMessage.getMessage() will be used
     * @return            The same instance of LogEntryEventBuilder, useful for chaining methods
     */
    global LogEntryEventBuilder setMessage(LogMessage logMessage) {
        if (this.shouldSave == false) {
            return this;
        }

        return this.setMessage(logMessage.getMessage());
    }

    /**
     * Sets the log entry event's message field
     * @param  message The instance of LogMessage to use - LogMessage.getMessage() will be used
     * @return         The same instance of LogEntryEventBuilder, useful for chaining methods
     */
    global LogEntryEventBuilder setMessage(String message) {
        if (this.shouldSave == false) {
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

    /**
     * Sets the log entry event's exception fields
     * @param  apexException The instance of an Exception to use.
     * @return               The same instance of LogEntryEventBuilder, useful for chaining methods
     */
    global LogEntryEventBuilder setExceptionDetails(Exception apexException) {
        if (this.shouldSave == false) {
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

    /**
     * Sets the log entry event's record fields
     * @param  record The SObject record related to the entry. The JSON of the record is automatically added to the entry
     * @return        The same instance of LogEntryEventBuilder, useful for chaining methods
     */
    global LogEntryEventBuilder setRecordId(SObject record) {
        if (this.shouldSave == false) {
            return this;
        }

        String truncatedRecordJson = truncateFieldValue(Schema.LogEntryEvent__e.RecordJson__c, Json.serializePretty(record));
        this.logEntryEvent.RecordJson__c = truncatedRecordJson;

        return this.setRecordId(record.Id);
    }

    /**
     * Sets the log entry event's record fields
     * @param  recordId The ID of the SObject record related to the entry
     * @return          The same instance of LogEntryEventBuilder, useful for chaining methods
     */
    global LogEntryEventBuilder setRecordId(Id recordId) {
        if (this.shouldSave == false) {
            return this;
        }

        this.logEntryEvent.RecordId__c = recordId;
        return this;
    }

    /**
     * Sets a comma-separate list of strings on the LogEntryEvent__e, which ultimately becomes Topic & TopicAssignment records on Log__c and LogEntry__c
     * @param  topics The list of strings to use as topics for the current entry
     * @return        The same instance of LogEntryEventBuilder, useful for chaining methods
     */
    public LogEntryEventBuilder setTopics(List<String> topics) {
        if (this.shouldSave == false) {
            return this;
        }

        this.logEntryEvent.Topics__c = getTopicsString(topics);
        return this;
    }

    /**
     * Parses the provided stack trace and sets the log entry's origin & stack trace fields
     * @param  stackTraceString The Apex stack trace string to parse
     * @return                  The same instance of LogEntryEventBuilder, useful for chaining methods
     */
    global LogEntryEventBuilder parseStackTrace(String stackTraceString) {
        if (this.shouldSave == false) {
            return this;
        }

        // Stack traces are not returned for managed packages
        if (!isValidStackTrace(stackTraceString)) {
            return this;
        }

        List<String> stackTraceLines = new List<String>();
        for (String currentStackTraceLine : stackTraceString.split('\n')) {
            // Don't include the logging system's classes in the stack trace

            Boolean ignoreLine = false;
            for (String ignoredClass : IGNORED_CLASSES) {
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

    /**
     * Determines if this instance of LogEntryEventBuilder should be saved the next time that Logger.saveLog() is called
     * @return   Boolean
     */
    public Boolean shouldSave() {
        return this.shouldSave;
    }

    /**
     * Returns the LogEntryEvent__e record for this instance of LogEntryEventBuilder
     * @return   The LogEntryEvent__e record
     */
    public LogEntryEvent__e getLogEntryEvent() {
        if (this.shouldSave == false) {
            return null;
        }

        // Lazy-loading of some details to help minimize Apex heap size usage until needed
        if (this.detailsAreSet == false) {
            this.setOrganizationDetails();
            this.setNetworkDetails();
            this.setUserDetails();
            this.setUserSessionDetails();

            this.detailsAreSet = true;
        }

        // Salesforce does not provide precise datetimes in Apex triggers for platform events
        // Set the string value of timestamp to a second field as a workaround
        // See https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_api_considerations.htm
        if (this.logEntryEvent.Timestamp__c != null) {
            this.logEntryEvent.TimestampString__c = String.valueOf(this.logEntryEvent.Timestamp__c);
        }

        return this.logEntryEvent;
    }

    private void setOrganizationDetails() {
        if (this.shouldSave == false) {
            return;
        }

        String orgEnvironmentType;
        if (ORGANIZATION.IsSandbox == true && ORGANIZATION.TrialExpirationDate != null) {
            orgEnvironmentType = 'Scratch Org';
        } else if (ORGANIZATION.IsSandbox == true) {
            orgEnvironmentType = 'Sandbox';
        } else {
            orgEnvironmentType = 'Production';
        }

        this.logEntryEvent.OrganizationDomainUrl__c = Url.getOrgDomainUrl()?.toExternalForm();
        this.logEntryEvent.OrganizationEnvironmentType__c = orgEnvironmentType;
        this.logEntryEvent.OrganizationId__c = ORGANIZATION.Id;
        this.logEntryEvent.OrganizationInstanceName__c = ORGANIZATION.InstanceName;
        this.logEntryEvent.OrganizationName__c = ORGANIZATION.Name;
        this.logEntryEvent.OrganizationNamespacePrefix__c = ORGANIZATION.NamespacePrefix;
        this.logEntryEvent.OrganizationType__c = ORGANIZATION.OrganizationType;
    }

    private void setNetworkDetails() {
        if (this.shouldSave == false) {
            return;
        }

        if (NETWORK_SITE == null) {
            return;
        }

        this.logEntryEvent.NetworkName__c = (String) NETWORK_SITE.get('Name');
        this.logEntryEvent.NetworkLoginUrl__c = Network.getLoginUrl(NETWORK_SITE.ID);
        this.logEntryEvent.NetworkLogoutUrl__c = Network.getLogoutUrl(NETWORK_SITE.ID);
        this.logEntryEvent.NetworkSelfRegistrationUrl__c = Network.getSelfRegUrl(NETWORK_SITE.ID);
        this.logEntryEvent.NetworkUrlPathPrefix__c = (String) NETWORK_SITE.get('UrlPathPrefix');
    }

    private void setUserDetails() {
        if (this.shouldSave == false) {
            return;
        }

        this.logEntryEvent.LoggedByUsername__c = USER.Username;
        this.logEntryEvent.ProfileName__c = USER.Profile.Name;
        this.logEntryEvent.UserLicenseDefinitionKey__c = USER.Profile.UserLicense.LicenseDefinitionKey;
        this.logEntryEvent.UserLicenseId__c = USER.Profile.UserLicenseId;
        this.logEntryEvent.UserLicenseName__c = USER.Profile.UserLicense.Name;
        this.logEntryEvent.UserRoleName__c = USER.UserRole?.Name;
    }

    private void setUserSessionDetails() {
        if (this.shouldSave == false) {
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

    private static List<String> getIgnoredClasses() {
        return new List<String>{ Logger.class.getName(), LogMessage.class.getName(), LogEntryEventBuilder.class.getName() };
    }

    // TODO move namespace methods to separate Namespace class (again) if other classes end up needing this info
    /* private static Boolean hasNamespacePrefix() {
        return String.isNotBlank(NAMESPACE_PREFIX);
    } */

    private static String getNamespacePrefix() {
        String className = LogEntryEventBuilder.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

        return namespacePrefix;
    }

    // private static String getPrefixWithDelimiter(String delimiter) {
    //     return String.isBlank(getPrefix()) ? '' : getPrefix() + delimiter;
    // }

    private static Organization getOrganization() {
        return [SELECT Id, Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization];
    }

    private static SObject getNetwork() {
        if (Network.getNetworkId() == null) {
            return null;
        }

        String networkApiName = 'Network';
        // Networks (communities) may not be enabled in the org (no Network object), so run everything dynamically
        Boolean networksEnabled = Schema.getGlobalDescribe().containsKey(networkApiName);

        if (!networksEnabled) {
            return null;
        }

        String queryString = 'SELECT Id, Name, UrlPathPrefix FROM Network WHERE Id = :Network.getNetworkId()';

        return Database.query(queryString);
    }

    private static User getUser() {
        return [
            SELECT Id, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.LicenseDefinitionKey, Profile.UserLicense.Name, Username, UserRole.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
    }

    // TODO need to revisit Visualforce logic, re-add fields to either Log__c or LogEntry__c, etc.
    /* private static String getVisualforcePageName() {
        String visualforcePageName = ApexPages.currentPage() == null ? null : ApexPages.currentPage().getUrl();
        if (visualforcePageName != null && visualforcePageName.contains('?')) {
            visualforcePageName = visualforcePageName.substringBetween('apex/', '?');
        } else if (visualforcePageName != null) {
            visualforcePageName = visualforcePageName.substringAfter('apex/');
        }

        return visualforcePageName;
    } */

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

        // De-duplicate the list of topics
        topics = new List<String>(new Set<String>(topics));

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
