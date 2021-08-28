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
    private static final List<String> IGNORED_CLASSES = getIgnoredClasses();
    private static final String NAMESPACE_PREFIX = getNamespacePrefix();
    private static final Map<String, String> SOBJECT_NAME_TO_CLASSIFICATION = new Map<String, String>();
    private static final Map<String, String> SOBJECT_SUFFIX_TO_CLASSIFICATION = getSObjectSuffixToClassification();

    // These constants all involve queries and/or increasing heap size, so custom getters are used for lazy-loading
    // This avoids unnecessarily consuming resources when logging is disabled, etc.
    private static final AuthSession CACHED_AUTH_SESSION {
        get {
            if (CACHED_AUTH_SESSION == null) {
                CACHED_AUTH_SESSION = queryAuthSession();
            }
            return CACHED_AUTH_SESSION;
        }
        set;
    }

    private static final List<LogEntryDataMaskRule__mdt> CACHED_DATA_MASK_RULES {
        get {
            if (CACHED_DATA_MASK_RULES == null) {
                CACHED_DATA_MASK_RULES = loadDataMaskRules();
            }
            return CACHED_DATA_MASK_RULES;
        }
        set;
    }

    private static final SObject CACHED_NETWORK_SITE {
        get {
            if (CACHED_NETWORK_SITE == null) {
                CACHED_NETWORK_SITE = queryNetwork();
            }
            return CACHED_NETWORK_SITE;
        }
        set;
    }

    private static final Organization CACHED_ORGANIZATION {
        get {
            if (CACHED_ORGANIZATION == null) {
                CACHED_ORGANIZATION = queryOrganization();
            }
            return CACHED_ORGANIZATION;
        }
        set;
    }

    private static final String CACHED_ORGANIZATION_ENVIRONMENT_TYPE {
        get {
            if (CACHED_ORGANIZATION_ENVIRONMENT_TYPE == null) {
                CACHED_ORGANIZATION_ENVIRONMENT_TYPE = getOrganizationEnvironmentType();
            }
            return CACHED_ORGANIZATION_ENVIRONMENT_TYPE;
        }
        set;
    }

    private static final User CACHED_USER {
        get {
            if (CACHED_USER == null) {
                CACHED_USER = queryUser();
            }
            return CACHED_USER;
        }
        set;
    }

    private final LogEntryEvent__e logEntryEvent;
    private final LoggingLevel entryLoggingLevel;

    private Boolean detailsAreSet = false;
    private Boolean shouldSave;
    private Set<String> tags = new Set<String>();
    private Boolean tagDetailsAreSet = true;

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

        this.logEntryEvent = new LogEntryEvent__e(
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
            LimitsPublishImmediateDmlStatementsUsed__c = Limits.getPublishImmediateDML(),
            LimitsSoqlQueriesUsed__c = Limits.getQueries(),
            LimitsSoqlQueryLocatorRowsUsed__c = Limits.getQueryLocatorRows(),
            LimitsSoqlQueryRowsUsed__c = Limits.getQueryRows(),
            LimitsSoslSearchesUsed__c = Limits.getSoslQueries(),
            LoggingLevel__c = entryLoggingLevel.NAME(),
            LoggingLevelOrdinal__c = entryLoggingLevel.ORDINAL(),
            OriginType__c = 'Apex',
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
        String cleanedMessage;
        if (this.shouldSave == true || Test.isRunningTest() == true) {
            cleanedMessage = applyDataMaskRules(message);
            // To help with debugging unit tests, always run System.debug statement in a test context
            System.debug(this.entryLoggingLevel, cleanedMessage);
        }

        if (this.shouldSave == false) {
            return this;
        }

        Boolean messageMasked = cleanedMessage != message;
        Boolean messageTruncated = String.isNotBlank(cleanedMessage) && cleanedMessage.length() > Schema.LogEntryEvent__e.Message__c.getDescribe().getLength();
        this.logEntryEvent.Message__c = truncateFieldValue(Schema.LogEntryEvent__e.Message__c, cleanedMessage);
        this.logEntryEvent.MessageMasked__c = messageMasked;
        this.logEntryEvent.MessageTruncated__c = messageTruncated;

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

        String recordJson = getJson(record);
        String cleanedRecordJson = applyDataMaskRules(recordJson);
        Boolean recordJsonMasked = cleanedRecordJson != recordJson;

        this.logEntryEvent.RecordCollectionType__c = 'Single';
        this.logEntryEvent.RecordId__c = record.Id;
        this.logEntryEvent.RecordJson__c = cleanedRecordJson;
        this.logEntryEvent.RecordJsonMasked__c = recordJsonMasked;
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
        this.tagDetailsAreSet = false;
        return this;
    }

    /**
     * @description Appends the tag to the existing list of tags
     * @param  tags The string to use as a tag for the current entry
     * @return        The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder addTags(List<String> tags) {
        if (tags == null || tags.isEmpty()) {
            return this;
        }

        for (String tag : tags) {
            this.addTag(tag);
        }
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
        if (this.detailsAreSet == false) {
            if (Logger.getUserSettings().AnonymousMode__c == false) {
                this.setUserDetails();
                this.setUserSessionDetails();
            }
            this.setNetworkDetails();
            this.setTransactionDetails();
            this.detailsAreSet = true;
        }

        // getLogEntryEvent() and addTag() could both be called multiple times
        // for the same instance of LogEntryBuilder, so tags are set (if needed)
        // each time getLogEntryEvent() is called, whereas methods executed above (using Boolean
        // this.detailsAreSet) only need to be run once
        if (this.tagDetailsAreSet == false) {
            this.setTagsDetails();
        }

        // Salesforce does not provide precise datetimes in Apex triggers for platform events
        // Set the string value of timestamp to a second field as a workaround
        // See https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_api_considerations.htm
        if (this.logEntryEvent.Timestamp__c != null) {
            this.logEntryEvent.TimestampString__c = String.valueOf(this.logEntryEvent.Timestamp__c.getTime());
        }

        return this.logEntryEvent;
    }

    private void setNetworkDetails() {
        if (CACHED_NETWORK_SITE == null) {
            return;
        }

        this.logEntryEvent.NetworkName__c = (String) CACHED_NETWORK_SITE.get('Name');
        this.logEntryEvent.NetworkLoginUrl__c = Network.getLoginUrl(CACHED_NETWORK_SITE.ID);
        this.logEntryEvent.NetworkLogoutUrl__c = Network.getLogoutUrl(CACHED_NETWORK_SITE.ID);
        this.logEntryEvent.NetworkSelfRegistrationUrl__c = Network.getSelfRegUrl(CACHED_NETWORK_SITE.ID);
        this.logEntryEvent.NetworkUrlPathPrefix__c = (String) CACHED_NETWORK_SITE.get('UrlPathPrefix');
    }

    private void setTagsDetails() {
        if (this.tags.isEmpty() == true || this.tagDetailsAreSet == true) {
            return;
        }

        this.logEntryEvent.Tags__c = String.escapeSingleQuotes(String.join(new List<String>(this.tags), '\n'));
    }

    private void setTransactionDetails() {
        this.logEntryEvent.ApiVersion__c = API_VERSION;
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
        this.logEntryEvent.LimitsPublishImmediateDmlStatementsMax__c = Limits.getLimitPublishImmediateDML();
        this.logEntryEvent.LimitsSoqlQueriesMax__c = Limits.getLimitQueries();
        this.logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c = Limits.getLimitQueryLocatorRows();
        this.logEntryEvent.LimitsSoqlQueryRowsMax__c = Limits.getLimitQueryRows();
        this.logEntryEvent.LimitsSoslSearchesMax__c = Limits.getLimitSoslQueries();
        this.logEntryEvent.OrganizationDomainUrl__c = Url.getOrgDomainUrl()?.toExternalForm();
        this.logEntryEvent.OrganizationEnvironmentType__c = CACHED_ORGANIZATION_ENVIRONMENT_TYPE;
        this.logEntryEvent.OrganizationId__c = CACHED_ORGANIZATION.Id;
        this.logEntryEvent.OrganizationInstanceName__c = CACHED_ORGANIZATION.InstanceName;
        this.logEntryEvent.OrganizationName__c = CACHED_ORGANIZATION.Name;
        this.logEntryEvent.OrganizationNamespacePrefix__c = CACHED_ORGANIZATION.NamespacePrefix;
        this.logEntryEvent.OrganizationType__c = CACHED_ORGANIZATION.OrganizationType;
    }

    private void setUserDetails() {
        this.logEntryEvent.LoggedById__c = CACHED_USER.Id;
        this.logEntryEvent.LoggedByUsername__c = CACHED_USER.Username;
        this.logEntryEvent.ProfileName__c = CACHED_USER.Profile.Name;
        this.logEntryEvent.UserLicenseDefinitionKey__c = CACHED_USER.Profile.UserLicense.LicenseDefinitionKey;
        this.logEntryEvent.UserLicenseId__c = CACHED_USER.Profile.UserLicenseId;
        this.logEntryEvent.UserLicenseName__c = CACHED_USER.Profile.UserLicense.Name;
        this.logEntryEvent.UserRoleName__c = CACHED_USER.UserRole?.Name;
    }

    private void setUserSessionDetails() {
        LoggingLevel userLoggingLevel = Logger.getUserLoggingLevel();

        this.logEntryEvent.Locale__c = UserInfo.getLocale();
        this.logEntryEvent.NetworkId__c = Network.getNetworkId();
        this.logEntryEvent.LoginHistoryId__c = CACHED_AUTH_SESSION?.LoginHistoryId;
        this.logEntryEvent.LoginApplication__c = CACHED_AUTH_SESSION?.LoginHistory.Application;
        this.logEntryEvent.LoginBrowser__c = CACHED_AUTH_SESSION?.LoginHistory.Browser;
        this.logEntryEvent.LoginPlatform__c = CACHED_AUTH_SESSION?.LoginHistory.Platform;
        this.logEntryEvent.LoginType__c = CACHED_AUTH_SESSION?.LoginType;
        this.logEntryEvent.LogoutUrl__c = CACHED_AUTH_SESSION?.LogoutUrl;
        this.logEntryEvent.ProfileId__c = UserInfo.getProfileId();
        this.logEntryEvent.SessionId__c = CACHED_AUTH_SESSION?.Id;
        this.logEntryEvent.SessionSecurityLevel__c = CACHED_AUTH_SESSION?.SessionSecurityLevel;
        this.logEntryEvent.SessionType__c = CACHED_AUTH_SESSION?.SessionType;
        this.logEntryEvent.SourceIp__c = CACHED_AUTH_SESSION?.SourceIp;
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

    // Private static TestVisible methods
    @TestVisible
    private static void addMockDataMaskRule(LogEntryDataMaskRule__mdt dataMaskRule) {
        CACHED_DATA_MASK_RULES.add(dataMaskRule);
    }

    private static String applyDataMaskRules(String dataInput) {
        if (Logger.getUserSettings().ApplyDataMaskRules__c == false) {
            return dataInput;
        }

        for (LogEntryDataMaskRule__mdt dataMaskRule : CACHED_DATA_MASK_RULES) {
            dataInput = dataInput.replaceAll(dataMaskRule.SensitiveDataRegEx__c, dataMaskRule.ReplacementRegEx__c);
        }
        return dataInput;
    }

    // Private static helper methods
    private static String getApiVersion() {
        // Small hack to determine the org's current API version (since Apex doesn't natively provide it)
        // Serializing any SObject w/ an ID will include the API version
        // So, use UserInfo.getUserId() to create the current user's record without querying
        // Then parse the JSON to get the API version
        // Expected JSON: {"attributes":{"type":"User","url":"/services/data/v52.0/sobjects/User/005J000000AugnYIAR"}
        String userJson = JSON.serialize(new User(Id = UserInfo.getUserId()));
        return userJson.substringAfter('/data/').substringBefore('/sobjects/User');
    }

    private static List<LogEntryDataMaskRule__mdt> loadDataMaskRules() {
        List<LogEntryDataMaskRule__mdt> activeDataMaskRules = new List<LogEntryDataMaskRule__mdt>();
        for (LogEntryDataMaskRule__mdt dataMaskRule : LogEntryDataMaskRule__mdt.getAll().values()) {
            if (dataMaskRule.IsEnabled__c == true) {
                activeDataMaskRules.add(dataMaskRule);
            }
        }
        if (Test.isRunningTest() == true) {
            // Tests shouldn't rely on the actual CMDT rules in the org
            // Clear the org's loaded records during tests, and mock via addMockDataMaskRule()
            activeDataMaskRules.clear();
        }
        return activeDataMaskRules;
    }

    private static List<String> getIgnoredClasses() {
        return new List<String>{
            ComponentLogger.class.getName(),
            FlowLogEntry.class.getName(),
            FlowRecordLogEntry.class.getName(),
            FlowCollectionLogEntry.class.getName(),
            FlowLogger.class.getName(),
            Logger.class.getName(),
            LogMessage.class.getName(),
            LogEntryEventBuilder.class.getName()
        };
    }

    private static String getJson(SObject record) {
        SObject strippedRecord = stripInaccessible(new List<SObject>{ record }).get(0);
        return truncateFieldValue(Schema.LogEntryEvent__e.RecordJson__c, JSON.serializePretty(strippedRecord));
    }

    private static String getJson(List<SObject> records) {
        List<SObject> strippedRecords = stripInaccessible(records);
        return truncateFieldValue(Schema.LogEntryEvent__e.RecordJson__c, JSON.serializePretty(strippedRecords));
    }

    private static String getOrganizationEnvironmentType() {
        String orgEnvironmentType;
        if (CACHED_ORGANIZATION.IsSandbox == true && CACHED_ORGANIZATION.TrialExpirationDate != null) {
            orgEnvironmentType = 'Scratch Org';
        } else if (CACHED_ORGANIZATION.IsSandbox == true) {
            orgEnvironmentType = 'Sandbox';
        } else {
            orgEnvironmentType = 'Production';
        }
        return orgEnvironmentType;
    }

    private static String getNamespacePrefix() {
        String className = LogEntryEventBuilder.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

        return namespacePrefix;
    }

    private static String getSObjectClassification(Schema.SObjectType sobjectType) {
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

    private static String getSObjectTypeNamespace(Schema.SObjectType sobjectType) {
        String sobjectFullName = sobjectType.getDescribe().getName();
        String sobjectLocalName = sobjectType.getDescribe().getLocalName();

        // Remove the trailing '__' if present
        String namespace = sobjectFullName.replace(sobjectLocalName, '').replace('__', '');
        if (String.isBlank(namespace)) {
            namespace = null;
        }
        return namespace;
    }

    private static Map<String, String> getSObjectSuffixToClassification() {
        // TODO add sample metadata for external object + picklist value + test
        // Example: MyExternalObject__x
        // '__mdt' => 'External Object'

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
        if (String.isBlank(stackTraceString) || stackTraceString == '()' || stackTraceString == '(' + NAMESPACE_PREFIX + ')') {
            return false;
        }

        return true;
    }

    private static AuthSession queryAuthSession() {
        if (String.isBlank(UserInfo.getSessionId())) {
            return new AuthSession();
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
        return sessions.isEmpty() ? new AuthSession() : sessions.get(0);
    }

    private static SObject queryNetwork() {
        Id networkId = Network.getNetworkId();
        if (networkId == null || Schema.getGlobalDescribe().containsKey('Network') == false) {
            return null;
        }

        // Networks (aka experience sites aka community sites aka portal sites ò_ô)
        // may not be enabled in the org (no Network object), so run everything dynamically
        String queryString = 'SELECT Id, Name, UrlPathPrefix FROM Network WHERE Id = :networkId';
        return Database.query(queryString);
    }

    private static Organization queryOrganization() {
        return [SELECT Id, Name, InstanceName, IsSandbox, NamespacePrefix, OrganizationType, TrialExpirationDate FROM Organization];
    }

    private static User queryUser() {
        return [
            SELECT Id, Profile.Name, Profile.UserLicenseId, Profile.UserLicense.LicenseDefinitionKey, Profile.UserLicense.Name, Username, UserRole.Name
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
    }

    private static List<SObject> stripInaccessible(List<SObject> records) {
        if (
            Logger.getUserSettings().StripInaccessibleRecordFields__c == false ||
            records == null ||
            records.get(0).getSObjectType() == Schema.AggregateResult.SObjectType
        ) {
            return records;
        }

        SObjectAccessDecision securityDecision = Security.stripInaccessible(AccessType.READABLE, records, false);
        return securityDecision.getRecords();
    }

    private static String truncateFieldValue(Schema.SObjectField field, String value) {
        Integer fieldMaxLength = field.getDescribe().getLength();
        return value?.left(fieldMaxLength);
    }
}
