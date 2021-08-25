//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Builder class that generates each `LogEntryEvent__e` record
 * @see Logger
 */
global with sharing class LogEntryEventBuilder {
    private static final String API_VERSION = getApiVersion();
    private static final AuthSession AUTH_SESSION = getAuthSession();
    @TestVisible
    private static final List<LogEntryDataMaskRule__mdt> DATA_MASK_RULES = getDataMaskRules();
    private static final List<String> IGNORED_CLASSES = getIgnoredClasses();
    private static final String NAMESPACE_PREFIX = getNamespacePrefix();
    private static final SObject NETWORK_SITE = getNetwork();
    private static final Organization ORGANIZATION = getOrganization();
    private static final String ORIGIN_TYPE_APEX = 'Apex';
    private static final User USER = getUser();
    private static final Map<String, String> SOBJECT_NAME_TO_CLASSIFICATION = new Map<String, String>();
    private static final Map<String, String> SOBJECT_SUFFIX_TO_CLASSIFICATION = getSObjectSuffixToClassification();

    private final LogEntryEvent__e logEntryEvent;
    private final LoggingLevel entryLoggingLevel;

    private Boolean detailsAreSet = false;
    private Boolean shouldSave;
    private List<String> tags = new List<String>();

    /**
     * @description Used by `Logger` to instantiate a new instance of `LogEntryEventBuilder`
     * @param  entryLoggingLevel The `LoggingLevel` enum to use for the builder's instance of `LogEntryEvent__e`
     * @param  shouldSave        Determines if the builder's instance of `LogEntryEvent__e` should be saved
     * @return                   The new instance of `LogEntryEventBuilder`
     */
    public LogEntryEventBuilder(LoggingLevel entryLoggingLevel, Boolean shouldSave) {
        this.entryLoggingLevel = entryLoggingLevel;
        this.shouldSave = shouldSave;

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

        this.logEntryEvent = new LogEntryEvent__e(
            ApiVersion__c = API_VERSION,
            LimitsAggregateQueriesMax__c = Limits.getLimitAggregateQueries(),
            LimitsAggregateQueriesUsed__c = Limits.getAggregateQueries(),
            LimitsAsyncCallsMax__c = Limits.getLimitAsyncCalls(),
            LimitsAsyncCallsUsed__c = Limits.getAsyncCalls(),
            LimitsCalloutsMax__c = Limits.getLimitCallouts(),
            LimitsCalloutsUsed__c = Limits.getCallouts(),
            LimitsCpuTimeMax__c = Limits.getLimitCpuTime(),
            LimitsCpuTimeUsed__c = Limits.getCpuTime(),
            LimitsDmlRowsMax__c = Limits.getLimitDmlRows(),
            LimitsDmlRowsUsed__c = Limits.getDmlRows(),
            LimitsDmlStatementsMax__c = Limits.getLimitDmlStatements(),
            LimitsDmlStatementsUsed__c = Limits.getDmlStatements(),
            LimitsEmailInvocationsMax__c = Limits.getLimitEmailInvocations(),
            LimitsEmailInvocationsUsed__c = Limits.getEmailInvocations(),
            LimitsFutureCallsMax__c = Limits.getLimitFutureCalls(),
            LimitsFutureCallsUsed__c = Limits.getFutureCalls(),
            LimitsHeapSizeMax__c = Limits.getLimitHeapSize(),
            LimitsHeapSizeUsed__c = Limits.getHeapSize(),
            LimitsMobilePushApexCallsMax__c = Limits.getLimitMobilePushApexCalls(),
            LimitsMobilePushApexCallsUsed__c = Limits.getMobilePushApexCalls(),
            LimitsQueueableJobsMax__c = Limits.getLimitQueueableJobs(),
            LimitsQueueableJobsUsed__c = Limits.getQueueableJobs(),
            LimitsPublishImmediateDmlStatementsMax__c = Limits.getLimitPublishImmediateDML(),
            LimitsPublishImmediateDmlStatementsUsed__c = Limits.getPublishImmediateDML(),
            LimitsSoqlQueriesMax__c = Limits.getLimitQueries(),
            LimitsSoqlQueriesUsed__c = Limits.getQueries(),
            LimitsSoqlQueryLocatorRowsMax__c = Limits.getLimitQueryLocatorRows(),
            LimitsSoqlQueryLocatorRowsUsed__c = Limits.getQueryLocatorRows(),
            LimitsSoqlQueryRowsMax__c = Limits.getLimitQueryRows(),
            LimitsSoqlQueryRowsUsed__c = Limits.getQueryRows(),
            LimitsSoslSearchesMax__c = Limits.getLimitSoslQueries(),
            LimitsSoslSearchesUsed__c = Limits.getSoslQueries(),
            LoggingLevel__c = entryLoggingLevel.NAME(),
            LoggingLevelOrdinal__c = entryLoggingLevel.ORDINAL(),
            OrganizationDomainUrl__c = Url.getOrgDomainUrl()?.toExternalForm(),
            OrganizationEnvironmentType__c = orgEnvironmentType,
            OrganizationId__c = ORGANIZATION.Id,
            OrganizationInstanceName__c = ORGANIZATION.InstanceName,
            OrganizationName__c = ORGANIZATION.Name,
            OrganizationNamespacePrefix__c = ORGANIZATION.NamespacePrefix,
            OrganizationType__c = ORGANIZATION.OrganizationType,
            OriginType__c = ORIGIN_TYPE_APEX,
            Timestamp__c = System.now(),
            EpochTimestamp__c = System.now().getTime(),
            TriggerIsExecuting__c = Trigger.isExecuting,
            TriggerOperationType__c = Trigger.operationType == null ? null : Trigger.operationType.name(),
            TriggerSObjectType__c = Trigger.new == null ? null : String.valueOf(Trigger.new.getSObjectType())
        );

        DmlException stackTraceException = new DmlException();
        this.parseStackTrace(stackTraceException.getStackTraceString());
    }

    /**
     * @description Sets the log entry event's message field
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setMessage(LogMessage logMessage) {
        if (this.shouldSave == false && Test.isRunningTest() == false) {
            return this;
        }

        return this.setMessage(logMessage.getMessage());
    }

    /**
     * @description Sets the log entry event's message field
     * @param  message The string to use to set the entry's message field
     * @return         The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setMessage(String message) {
        String sanitizedMessage;
        if (this.shouldSave == true || Test.isRunningTest() == true) {
            sanitizedMessage = sanitizeMessage(message);
            // To help with debugging unit tests, always run System.debug statement in a test context
            System.debug(this.entryLoggingLevel, sanitizedMessage);
        }

        if (this.shouldSave == false) {
            return this;
        }

        this.logEntryEvent.Message__c = sanitizedMessage;
        this.logEntryEvent.MessageTruncated__c = sanitizedMessage.length() < message.length();

        return this;
    }

    /**
     * @description Sets the log entry event's exception fields
     * @param  apexException The instance of an `Exception` to use.
     * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
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

    // DML-result builder methods. All* of the Result classes behave the same (*except Upsert)
    // ...but Salesforce didn't bother to use an interface for the classes, so instead - overloads!
    /**
     * @description Sets the log entry event's database operation result fields
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.DeleteResult deleteResult) {
        if (this.shouldSave == false || deleteResult == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(deleteResult));
        this.logEntryEvent.DatabaseResultType__c = Database.DeleteResult.class.getName();

        return this.setRecordId(deleteResult.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.MergeResult mergeResult) {
        if (this.shouldSave == false || mergeResult == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(mergeResult));
        this.logEntryEvent.DatabaseResultType__c = Database.MergeResult.class.getName();

        return this.setRecordId(mergeResult.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.SaveResult saveResult) {
        if (this.shouldSave == false || saveResult == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(saveResult));
        this.logEntryEvent.DatabaseResultType__c = Database.SaveResult.class.getName();

        return this.setRecordId(saveResult.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.UpsertResult upsertResult) {
        if (this.shouldSave == false || upsertResult == null) {
            return this;
        }

        // Upsert has 2 subtypes (surprise!) - insert and update - so, UpsertResult has an extra method to take into account
        String subtype = upsertResult.isCreated() ? 'Insert' : 'Update';

        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(upsertResult));
        this.logEntryEvent.DatabaseResultType__c = Database.UpsertResult.class.getName() + '.' + subtype;

        return this.setRecordId(upsertResult.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.UndeleteResult undeleteResult) {
        if (this.shouldSave == false || undeleteResult == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(undeleteResult));
        this.logEntryEvent.DatabaseResultType__c = Database.UndeleteResult.class.getName();

        return this.setRecordId(undeleteResult.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(List<Database.DeleteResult> deleteResults) {
        if (this.shouldSave == false || deleteResults == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'List';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(deleteResults));
        this.logEntryEvent.DatabaseResultType__c = Database.DeleteResult.class.getName();

        return this;
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  mergeResults The list of `Database.MergeResult` instances to log
     * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(List<Database.MergeResult> mergeResults) {
        if (this.shouldSave == false || mergeResults == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'List';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(mergeResults));
        this.logEntryEvent.DatabaseResultType__c = Database.MergeResult.class.getName();

        return this;
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  saveResults The list of `Database.SaveResult` instances to log
     * @return             The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(List<Database.SaveResult> saveResults) {
        if (this.shouldSave == false || saveResults == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'List';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(saveResults));
        this.logEntryEvent.DatabaseResultType__c = Database.SaveResult.class.getName();

        return this;
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  upsertResults The list of `Database.UpsertResult` instances to log
     * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(List<Database.UpsertResult> upsertResults) {
        if (this.shouldSave == false || upsertResults == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'List';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(upsertResults));
        this.logEntryEvent.DatabaseResultType__c = Database.UpsertResult.class.getName();

        return this;
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  undeleteResults The list of `Database.UndeleteResult` instances to log
     * @return                 The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(List<Database.UndeleteResult> undeleteResults) {
        if (this.shouldSave == false || undeleteResults == null) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionType__c = 'List';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(undeleteResults));
        this.logEntryEvent.DatabaseResultType__c = Database.UndeleteResult.class.getName();

        return this;
    }

    /**
     * @description Deprecated - use `setRecord(Id recordId)` instead
     */
    global LogEntryEventBuilder setRecordId(Id recordId) {
        return this.setRecord(recordId);
    }

    /**
     * @description Deprecated - use `setRecord(SObject record)` instead
     */
    global LogEntryEventBuilder setRecordId(SObject record) {
        return this.setRecord(record);
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  recordId The ID of the SObject record related to the entry
     * @return          The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setRecord(Id recordId) {
        if (this.shouldSave == false || String.isBlank(recordId)) {
            return this;
        }

        this.logEntryEvent.RecordCollectionType__c = 'Single';
        this.logEntryEvent.RecordId__c = recordId;
        this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(recordId.getSObjectType());
        this.logEntryEvent.RecordSObjectType__c = recordId.getSObjectType().getDescribe().getName();
        return this;
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  record The `SObject` record related to the entry. The JSON of the record is automatically added to the entry
     * @return        The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setRecord(SObject record) {
        if (this.shouldSave == false || record == null) {
            return this;
        }

        this.logEntryEvent.RecordCollectionType__c = 'Single';
        this.logEntryEvent.RecordId__c = record.Id;
        this.logEntryEvent.RecordJson__c = getJson(record);
        this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(record.getSObjectType());
        this.logEntryEvent.RecordSObjectType__c = record.getSObjectType().getDescribe().getName();
        this.logEntryEvent.RecordSObjectTypeNamespace__c = getSObjectTypeNamespace(record.getSObjectType());

        return this;
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  records The list of `SObject` records related to the entry. The JSON of the list is automatically added to the entry
     * @return         The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setRecord(List<SObject> records) {
        if (this.shouldSave == false || records == null) {
            return this;
        }

        Schema.SObjectType sobjectType = records.getSObjectType() != null ? records.getSObjectType() : records.get(0).getSObjectType();
        String sobjectTypeName = sobjectType?.getDescribe().getName();

        this.logEntryEvent.RecordCollectionType__c = 'List';
        this.logEntryEvent.RecordJson__c = getJson(records);
        this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(sobjectType);
        this.logEntryEvent.RecordSObjectType__c = sobjectTypeName;
        this.logEntryEvent.RecordSObjectTypeNamespace__c = getSObjectTypeNamespace(sobjectType);

        return this;
    }

    /**
     * @description Appends the tag to the existing list of tags
     * @param  tags The string to use as a tag for the current entry
     * @return        The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder addTag(String tag) {
        if (this.shouldSave == false || String.isBlank(tag)) {
            return this;
        }

        this.tags.add(tag);
        return this;
    }

    /**
     * @description Appends the tag to the existing list of tags
     * @param  tags The string to use as a tag for the current entry
     * @return        The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder addTags(List<String> tags) {
        if (this.shouldSave == false || tags == null || tags.isEmpty()) {
            return this;
        }

        this.tags.addAll(tags);
        return this;
    }

    /**
     * @description Deprecated - use `addTags(List<String> tags)` instead.
     *              This method will be removed in a future release
     */
    public LogEntryEventBuilder setTopics(List<String> tags) {
        return this.addTags(tags);
    }

    /**
     * @description Parses the provided stack trace and sets the log entry's origin & stack trace fields
     * @param  stackTraceString The Apex stack trace string to parse
     * @return                  The same instance of `LogEntryEventBuilder`, useful for chaining methods
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
            this.logEntryEvent.StackTrace__c = truncateFieldValue(Schema.LogEntryEvent__e.StackTrace__c, stackTraceString);
        }

        return this;
    }

    /**
     * @description Determines if this instance of `LogEntryEventBuilder` should be saved the next time that `Logger.saveLog()` is called
     * @return   Boolean
     */
    public Boolean shouldSave() {
        return this.shouldSave;
    }

    /**
     * @description Returns the `LogEntryEvent__e` record for this instance of LogEntryEventBuilder
     * @return   The `LogEntryEvent__e` record
     */
    public LogEntryEvent__e getLogEntryEvent() {
        if (this.shouldSave == false) {
            return null;
        }

        // Lazy-loading of some details to help minimize Apex heap size usage until needed
        if (this.detailsAreSet == false && Logger.getUserSettings().AnonymousMode__c == false) {
            this.setNetworkDetails();
            this.setUserDetails();
            this.setUserSessionDetails();

            this.detailsAreSet = true;
        }

        this.logEntryEvent.Tags__c = getTagsString(this.tags);

        // Salesforce does not provide precise datetimes in Apex triggers for platform events
        // Set the string value of timestamp to a second field as a workaround
        // See https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_api_considerations.htm
        if (this.logEntryEvent.Timestamp__c != null) {
            this.logEntryEvent.TimestampString__c = String.valueOf(this.logEntryEvent.Timestamp__c.getTime());
        }

        return this.logEntryEvent;
    }

    private void setNetworkDetails() {
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
        this.logEntryEvent.LoggedById__c = USER.Id;
        this.logEntryEvent.LoggedByUsername__c = USER.Username;
        this.logEntryEvent.ProfileName__c = USER.Profile.Name;
        this.logEntryEvent.UserLicenseDefinitionKey__c = USER.Profile.UserLicense.LicenseDefinitionKey;
        this.logEntryEvent.UserLicenseId__c = USER.Profile.UserLicenseId;
        this.logEntryEvent.UserLicenseName__c = USER.Profile.UserLicense.Name;
        this.logEntryEvent.UserRoleName__c = USER.UserRole?.Name;
    }

    private void setUserSessionDetails() {
        LoggingLevel userLoggingLevel = Logger.getUserLoggingLevel();

        this.logEntryEvent.Locale__c = UserInfo.getLocale();
        this.logEntryEvent.NetworkId__c = Network.getNetworkId();
        this.logEntryEvent.LoginHistoryId__c = AUTH_SESSION?.LoginHistoryId;
        this.logEntryEvent.LoginApplication__c = AUTH_SESSION?.LoginHistory.Application;
        this.logEntryEvent.LoginBrowser__c = AUTH_SESSION?.LoginHistory.Browser;
        this.logEntryEvent.LoginPlatform__c = AUTH_SESSION?.LoginHistory.Platform;
        this.logEntryEvent.LoginType__c = AUTH_SESSION?.LoginType;
        this.logEntryEvent.LogoutUrl__c = AUTH_SESSION?.LogoutUrl;
        this.logEntryEvent.ProfileId__c = UserInfo.getProfileId();
        this.logEntryEvent.SessionId__c = AUTH_SESSION?.Id;
        this.logEntryEvent.SessionSecurityLevel__c = AUTH_SESSION?.SessionSecurityLevel;
        this.logEntryEvent.SessionType__c = AUTH_SESSION?.SessionType;
        this.logEntryEvent.SourceIp__c = AUTH_SESSION?.SourceIp;
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

    private String getSObjectClassification(Schema.SObjectType sobjectType) {
        String sobjectName = sobjectType.getDescribe().getName();

        // Check the map to see if we've already determined the classification for this SObject type
        if (SOBJECT_NAME_TO_CLASSIFICATION.containsKey(sobjectName)) {
            return SOBJECT_NAME_TO_CLASSIFICATION.get(sobjectName);
        }

        String sobjectClassification;

        // Custom settings and custom objects both end in '__c', so explicitly check if it's a custom setting
        if (sobjectType.getDescribe().isCustomSetting()) {
            sobjectClassification = 'Custom Setting Object';
        }

        for (String sobjectSuffix : SOBJECT_SUFFIX_TO_CLASSIFICATION.keySet()) {
            if (String.isBlank(sobjectClassification) && sobjectName.endsWith(sobjectSuffix)) {
                sobjectClassification = SOBJECT_SUFFIX_TO_CLASSIFICATION.get(sobjectSuffix);
                break;
            }
        }

        // Finally, if we still don't have a classification, assume it's a standard object
        if (String.isBlank(sobjectClassification) && sobjectType.getDescribe().isCustom() == false) {
            sobjectClassification = 'Standard Object';
        }

        // Cache the results in case there are other entries related to the same SObject Type
        SOBJECT_NAME_TO_CLASSIFICATION.put(sobjectName, sobjectClassification);

        return sobjectClassification;
    }

    private String getSObjectTypeNamespace(Schema.SObjectType sobjectType) {
        String sobjectFullName = sobjectType.getDescribe().getName();
        String sobjectLocalName = sobjectType.getDescribe().getLocalName();

        // Remove the trailing '__' if present
        String namespace = sobjectFullName.replace(sobjectLocalName, '').replace('__', '');
        if (String.isBlank(namespace)) {
            namespace = null;
        }
        return namespace;
    }

    // Private static methods
    private static AuthSession getAuthSession() {
        if (String.isBlank(UserInfo.getSessionId())) {
            return null;
        }

        // Scheduled jobs, batch jobs, invocables, future methods and queueables are ALL
        // run by the Automated Process user - attempting to access Auth.SessionManagement
        // methods as that user throws an UNCATCHABLE error. Let's sidestep that by querying AuthSession instead.

        List<AuthSession> sessions = [
            SELECT
                Id,
                LoginType,
                LoginHistoryId,
                LoginHistory.Application,
                LoginHistory.Browser,
                LoginHistory.Platform,
                LogoutUrl,
                SessionSecurityLevel,
                SessionType,
                SourceIp
            FROM AuthSession
            WHERE UsersId = :UserInfo.getUserId() AND IsCurrent = TRUE AND ParentId = NULL
        ];

        if (sessions.isEmpty()) {
            return null;
        } else {
            return sessions.get(0);
        }
    }

    private static String getApiVersion() {
        // Small hack to determine the org's current API version (since Apex doesn't natively provide it)
        // Serializing any SObject w/ an ID will include the API version
        // So, use UserInfo.getUserId() to create the current user's record without querying
        // Then parse the JSON to get the API version
        // Expected JSON: {"attributes":{"type":"User","url":"/services/data/v52.0/sobjects/User/005J000000AugnYIAR"}
        String userJson = JSON.serialize(new User(Id = UserInfo.getUserId()));
        return userJson.substringAfter('/data/').substringBefore('/sobjects/User');
    }

    private static List<LogEntryDataMaskRule__mdt> getDataMaskRules() {
        List<LogEntryDataMaskRule__mdt> rules = LogEntryDataMaskRule__mdt.getAll().values();
        if (Test.isRunningTest() == true) {
            rules.clear();
        }
        return rules;
    }

    private static List<String> getIgnoredClasses() {
        return new List<String>{ FlowLogger.class.getName(), Logger.class.getName(), LogMessage.class.getName(), LogEntryEventBuilder.class.getName() };
    }

    private static String getNamespacePrefix() {
        String className = LogEntryEventBuilder.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

        return namespacePrefix;
    }

    private static Map<String, String> getSObjectSuffixToClassification() {
        return new Map<String, String>{
            // Example: MyBigObject__b
            '__b' => 'Big Object',
            // Example: Log__c
            '__c' => 'Custom Object',
            // Example: LogEntryEvent__e
            '__e' => 'Platform Event Object',
            // Example: LogStatus__mdt
            '__mdt' => 'Custom Metadata Type Object',
            // Examples: AccountChangeEvent and Log__ChangeEvent
            'ChangeEvent' => 'Change Event Object',
            // Examples: AccountFeed and Log__Feed
            'Feed' => 'Chatter Feed Object',
            // Examples: AccountHistory and Log__History
            'History' => 'Field History Tracking Object',
            // Examples: AccountShare and Log__Share
            'Share' => 'Record Share Object'
        };
    }

    private static Organization getOrganization() {
        return [SELECT Id, Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization];
    }

    private static SObject getNetwork() {
        Id networkId;
        if (Network.getNetworkId() == null) {
            return null;
        } else {
            networkId = Network.getNetworkId();
        }

        String networkApiName = 'Network';
        // Networks (communities) may not be enabled in the org (no Network object), so run everything dynamically
        Boolean networksEnabled = Schema.getGlobalDescribe().containsKey(networkApiName);

        if (!networksEnabled) {
            return null;
        }

        String queryString = 'SELECT Id, Name, UrlPathPrefix FROM Network WHERE Id = :networkId';

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

        if (stackTraceString == '()' || stackTraceString == '(' + NAMESPACE_PREFIX + ')') {
            return false;
        }

        return true;
    }

    private static String getJson(SObject record) {
        SObject localRecord = record.clone(false, false, false, false); // TODO
        if (Logger.getUserSettings().StripInaccessibleRecordFields__c == true) {
            SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, new List<SObject>{ localRecord });
            localRecord = securityDecision.getRecords().get(0);
        }

        return truncateFieldValue(Schema.LogEntryEvent__e.RecordJson__c, JSON.serializePretty(localRecord));
    }

    private static String getJson(List<SObject> records) {
        List<SObject> localRecords = records.clone(); // TODO false, false, false, false);
        if (Logger.getUserSettings().StripInaccessibleRecordFields__c == true) {
            SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, localRecords);
            localRecords = securityDecision.getRecords();
        }

        return truncateFieldValue(Schema.LogEntryEvent__e.RecordJson__c, JSON.serializePretty(localRecords));
    }

    private static String getTagsString(List<String> tags) {
        if (tags == null || tags.isEmpty()) {
            return null;
        }

        // De-duplicate the list of tags
        tags = new List<String>(new Set<String>(tags));

        return String.escapeSingleQuotes(String.join(tags, '\n'));
    }

    private static String sanitizeMessage(String message) {
        for (LogEntryDataMaskRule__mdt dataMaskRule : DATA_MASK_RULES) {

            Integer numberOfCharactersToDisplay = Integer.valueOf(dataMaskRule.NumberOfCharactersToDisplay__c);
            Pattern dataMaskPattern = Pattern.compile(dataMaskRule.MessageRegEx__c);

            Matcher dataMaskPatternMatcher = dataMaskPattern.matcher(message);
            while (dataMaskPatternMatcher.find() == true) {
                String matchingSubstring = message.substring(dataMaskPatternMatcher.start(), dataMaskPatternMatcher.end());

                String substringToMask = matchingSubstring.substring(0, matchingSubstring.length() - numberOfCharactersToDisplay);
                String mask = '';
                for (Integer i = 0; i < substringToMask.length(); i++) {
                    mask += dataMaskRule.MaskCharacter__c;
                }
                String maskedSubstring = mask + matchingSubstring.substring(matchingSubstring.length() - numberOfCharactersToDisplay);

                message = message.replace(matchingSubstring, maskedSubstring);
            }
        }

        return truncateFieldValue(Schema.LogEntryEvent__e.Message__c, message);
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
