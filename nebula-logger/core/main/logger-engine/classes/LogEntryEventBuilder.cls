//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Logger Engine
 * @description Builder class that generates each `LogEntryEvent__e` record
 * @see Logger
 */
@SuppressWarnings(
    'PMD.AvoidGlobalModifier, PMD.CognitiveComplexity, PMD.CyclomaticComplexity, PMD.ExcessiveClassLength, PMD.NcssTypeCount, PMD.PropertyNamingConventions, PMD.StdCyclomaticComplexity'
)
global with sharing class LogEntryEventBuilder {
    private static final Map<String, String> CACHED_SOBJECT_NAME_TO_CLASSIFICATION = new Map<String, String>();
    private static final User CURRENT_USER = new User(Id = System.UserInfo.getUserId(), ProfileId = System.UserInfo.getProfileId());
    private static final String HTTP_HEADER_FORMAT = '{0}: {1}';
    private static final String NEW_LINE_DELIMITER = '\n';

    private static String cachedOrganizationEnvironmentType;

    @TestVisible
    private static Id networkId = System.Network.getNetworkId();

    private final LogEntryEvent__e logEntryEvent;
    private final System.LoggingLevel entryLoggingLevel;
    private final String organizationEnvironmentType;
    private final LoggerSettings__c userSettings;

    @TestVisible
    private String debugMessage = '';
    private Boolean detailsAreSet = false;
    private Set<String> ignoredApexClasses = new Set<String>();
    private Boolean shouldSave;
    private Set<String> tags = new Set<String>();
    private Boolean tagDetailsAreSet = true;

    private static final Map<String, LogEntryDataMaskRule__mdt> CACHED_DATA_MASK_RULES {
        get {
            if (CACHED_DATA_MASK_RULES == null) {
                CACHED_DATA_MASK_RULES = loadDataMaskRules();
            }
            return CACHED_DATA_MASK_RULES;
        }
        set;
    }

    private static final LogEntryEvent__e LOG_ENTRY_EVENT_TEMPLATE {
        get {
            if (LOG_ENTRY_EVENT_TEMPLATE == null) {
                LOG_ENTRY_EVENT_TEMPLATE = getLogEntryEventTemplate();
            }
            return LOG_ENTRY_EVENT_TEMPLATE.clone();
        }
        set;
    }

    private static final String NAMESPACE_PREFIX {
        get {
            if (NAMESPACE_PREFIX == null) {
                NAMESPACE_PREFIX = getNamespacePrefix();
            }
            return NAMESPACE_PREFIX;
        }
        set;
    }

    private static final Map<String, String> SOBJECT_SUFFIX_TO_CLASSIFICATION {
        get {
            if (SOBJECT_SUFFIX_TO_CLASSIFICATION == null) {
                SOBJECT_SUFFIX_TO_CLASSIFICATION = getSObjectSuffixToClassification();
            }
            return SOBJECT_SUFFIX_TO_CLASSIFICATION;
        }
        set;
    }

    /**
     * @description Used by `Logger` to instantiate a new instance of `LogEntryEventBuilder`
     * @param  userSettings      The instance of `LoggerSettings__c` for the current to use to control any feature flags
     * @param  entryLoggingLevel The `LoggingLevel` value to use for the log entry
     * @param  shouldSave        Indicates if the builder's instance of `LogEntryEvent__e` should be saved
     * @param  ignoredOrigins    A `Set<String>` of the names of any Apex classes that should be ignored when parsing the entry's origin
     */
    @SuppressWarnings('PMD.ExcessiveParameterList, PMD.NcssConstructorCount')
    public LogEntryEventBuilder(LoggerSettings__c userSettings, System.LoggingLevel entryLoggingLevel, Boolean shouldSave, Set<String> ignoredOrigins) {
        this.shouldSave = shouldSave;
        if (this.shouldSave() == false) {
            return;
        }

        this.userSettings = userSettings;
        this.organizationEnvironmentType = getOrganizationEnvironmentType(userSettings);
        this.entryLoggingLevel = entryLoggingLevel;
        if (ignoredOrigins != null) {
            this.ignoredApexClasses.addAll(ignoredOrigins);
        }

        Datetime timestamp = System.now();
        this.logEntryEvent = new LogEntryEvent__e(
            EpochTimestamp__c = timestamp.getTime(),
            LimitsAggregateQueriesUsed__c = System.Limits.getAggregateQueries(),
            LimitsAsyncCallsUsed__c = System.Limits.getAsyncCalls(),
            LimitsCalloutsUsed__c = System.Limits.getCallouts(),
            LimitsCpuTimeUsed__c = System.Limits.getCpuTime(),
            LimitsDmlRowsUsed__c = System.Limits.getDmlRows(),
            LimitsDmlStatementsUsed__c = System.Limits.getDmlStatements(),
            LimitsEmailInvocationsUsed__c = System.Limits.getEmailInvocations(),
            LimitsFutureCallsUsed__c = System.Limits.getFutureCalls(),
            LimitsHeapSizeUsed__c = System.Limits.getHeapSize(),
            LimitsMobilePushApexCallsUsed__c = System.Limits.getMobilePushApexCalls(),
            LimitsQueueableJobsUsed__c = System.Limits.getQueueableJobs(),
            LimitsPublishImmediateDmlStatementsUsed__c = System.Limits.getPublishImmediateDML(),
            LimitsSoqlQueriesUsed__c = System.Limits.getQueries(),
            LimitsSoqlQueryLocatorRowsUsed__c = System.Limits.getQueryLocatorRows(),
            LimitsSoqlQueryRowsUsed__c = System.Limits.getQueryRows(),
            LimitsSoslSearchesUsed__c = System.Limits.getSoslQueries(),
            LoggingLevel__c = entryLoggingLevel.name(),
            LoggingLevelOrdinal__c = entryLoggingLevel.ordinal(),
            OriginType__c = 'Apex',
            Timestamp__c = timestamp,
            TriggerIsExecuting__c = Trigger.isExecuting,
            TriggerOperationType__c = Trigger.operationType?.name(),
            TriggerSObjectType__c = Trigger.new?.getSObjectType().getDescribe().getName()
        );

        this.parseStackTrace();
    }

    /**
     * @description Sets the log entry event's message field
     * @param  logMessage The instance of `LogMessage` to use to set the entry's message field
     * @return            The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setMessage(LogMessage logMessage) {
        if (this.shouldSave() == false && System.Test.isRunningTest() == false || logMessage == null) {
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
        // To help with debugging unit tests, always run System.debug statement in a test context
        if ((this.shouldSave() || System.Test.isRunningTest()) && this.logEntryEvent != null) {
            String cleanedMessage = applyDataMaskRules(message);
            Boolean messageMasked = cleanedMessage != message;
            String truncatedMessage = truncateFieldValue(Schema.LogEntryEvent__e.Message__c, cleanedMessage);
            Boolean messageTruncated =
                String.isNotBlank(cleanedMessage) && cleanedMessage.length() > Schema.LogEntryEvent__e.Message__c.getDescribe().getLength();

            this.logEntryEvent.Message__c = truncatedMessage;
            this.logEntryEvent.MessageMasked__c = messageMasked;
            this.logEntryEvent.MessageTruncated__c = messageTruncated;
            this.logToApexDebug(message);
        }
        return this;
    }

    /**
     * @description Sets the log entry event's exception fields
     * @param  apexException The instance of an `System.Exception` to use.
     * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setExceptionDetails(System.Exception apexException) {
        if (this.shouldSave() == false || apexException == null) {
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
    // but Salesforce didn't bother to use an interface for the classes, so instead - overloads!

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  leadConvertResult The instance of `Database.LeadConvertResult` to log
     * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.LeadConvertResult leadConvertResult) {
        if (this.shouldSave() == false) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionSize__c = 1;
        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(leadConvertResult));
        this.logEntryEvent.DatabaseResultType__c = Database.LeadConvertResult.class.getName();

        return this.setRecordId(leadConvertResult?.getLeadId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  leadConvertResults The list of `Database.LeadConvertResult`s to log
     * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(List<Database.LeadConvertResult> leadConvertResults) {
        if (this.shouldSave() == false) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionSize__c = leadConvertResults.size();
        this.logEntryEvent.DatabaseResultCollectionType__c = 'List';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(leadConvertResults));
        this.logEntryEvent.DatabaseResultType__c = Database.LeadConvertResult.class.getName();

        return this;
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  deleteResult The instance of `Database.DeleteResult` to log
     * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.DeleteResult deleteResult) {
        if (this.shouldSave() == false) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionSize__c = 1;
        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(deleteResult));
        this.logEntryEvent.DatabaseResultType__c = Database.DeleteResult.class.getName();

        return this.setRecordId(deleteResult?.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  mergeResult The instance of `Database.MergeResult` to log
     * @return             The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.MergeResult mergeResult) {
        if (this.shouldSave() == false) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionSize__c = 1;
        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(mergeResult));
        this.logEntryEvent.DatabaseResultType__c = Database.MergeResult.class.getName();

        return this.setRecordId(mergeResult?.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  saveResult The instance of `Database.SaveResult` to log
     * @return            The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.SaveResult saveResult) {
        if (this.shouldSave() == false) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionSize__c = 1;
        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(saveResult));
        this.logEntryEvent.DatabaseResultType__c = Database.SaveResult.class.getName();

        return this.setRecordId(saveResult?.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  upsertResult The instance of `Database.UpsertResult` to log
     * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.UpsertResult upsertResult) {
        if (this.shouldSave() == false) {
            return this;
        }

        // Upsert has 2 subtypes (surprise!) - insert and update - so, UpsertResult has an extra method to take into account
        String subtype = upsertResult.isCreated() ? 'Insert' : 'Update';

        this.logEntryEvent.DatabaseResultCollectionSize__c = 1;
        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(upsertResult));
        this.logEntryEvent.DatabaseResultType__c = Database.UpsertResult.class.getName() + '.' + subtype;

        return this.setRecordId(upsertResult?.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  undeleteResult The instance of `Database.UndeleteResult` to log
     * @return                The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(Database.UndeleteResult undeleteResult) {
        if (this.shouldSave() == false) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionSize__c = 1;
        this.logEntryEvent.DatabaseResultCollectionType__c = 'Single';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(undeleteResult));
        this.logEntryEvent.DatabaseResultType__c = Database.UndeleteResult.class.getName();

        return this.setRecordId(undeleteResult?.getId());
    }

    /**
     * @description Sets the log entry event's database operation result fields
     * @param  deleteResults The list of `Database.DeleteResult` instances to log
     * @return               The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setDatabaseResult(List<Database.DeleteResult> deleteResults) {
        if (this.shouldSave() == false) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionSize__c = deleteResults?.size();
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
        if (this.shouldSave() == false) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionSize__c = mergeResults?.size();
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
        if (this.shouldSave() == false) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionSize__c = saveResults?.size();
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
        if (this.shouldSave() == false) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionSize__c = upsertResults?.size();
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
        if (this.shouldSave() == false) {
            return this;
        }

        this.logEntryEvent.DatabaseResultCollectionSize__c = undeleteResults?.size();
        this.logEntryEvent.DatabaseResultCollectionType__c = 'List';
        this.logEntryEvent.DatabaseResultJson__c = truncateFieldValue(Schema.LogEntryEvent__e.DatabaseResultJson__c, JSON.serializePretty(undeleteResults));
        this.logEntryEvent.DatabaseResultType__c = Database.UndeleteResult.class.getName();

        return this;
    }

    /**
     * @description Deprecated - use `setRecord(Id recordId)` instead
     * @param recordId The id of the record to set.
     * @return An instance of LogEntryEventBuilder with a record associated wit recordId.
     */
    global LogEntryEventBuilder setRecordId(Id recordId) {
        return this.setRecord(recordId);
    }

    /**
     * @description Deprecated - use `setRecord(SObject record)` instead
     * @param record the record to set.
     * @return An instance of LogEntryEventBuilder with the given record.
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
        if (this.shouldSave() == false || String.isBlank(recordId)) {
            return this;
        }

        this.logEntryEvent.RecordCollectionSize__c = 1;
        this.logEntryEvent.RecordCollectionType__c = 'Single';
        this.logEntryEvent.RecordId__c = recordId;
        try {
            Schema.SObjectType sobjectType = recordId?.getSObjectType();
            this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(sobjectType);
            this.logEntryEvent.RecordSObjectType__c = sobjectType.getDescribe().getName();
        } catch (System.SObjectException sobjectException) {
            // Some SObject Types are considered template objects, such as CaseComment, AccountHistory,
            // ContactHistory, etc, so calling Id.getSObjectType() does not work for some types of record IDs
            if (sobjectException.getMessage().contains('Cannot locate Apex Type') == false) {
                throw sobjectException;
            }
        }
        return this;
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  record The `SObject` record related to the entry. The JSON of the record is automatically added to the entry
     * @return        The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setRecord(SObject record) {
        if (this.shouldSave() == false) {
            return this;
        }

        this.logEntryEvent.RecordCollectionSize__c = 1;
        this.logEntryEvent.RecordCollectionType__c = 'Single';

        String recordJson = getJson(record, userSettings.IsRecordFieldStrippingEnabled__c);
        if (record == null) {
            this.logEntryEvent.RecordJson__c = recordJson;
            this.logEntryEvent.RecordSObjectClassification__c = 'Unknown';
            this.logEntryEvent.RecordSObjectType__c = 'Unknown';
        } else {
            String cleanedRecordJson = applyDataMaskRules(recordJson);
            Boolean recordJsonMasked = cleanedRecordJson != recordJson;

            this.logEntryEvent.RecordId__c = record.Id;
            this.logEntryEvent.RecordJson__c = cleanedRecordJson;
            this.logEntryEvent.RecordJsonMasked__c = recordJsonMasked;
            this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(record.getSObjectType());
            this.logEntryEvent.RecordSObjectType__c = record.getSObjectType().getDescribe().getName();
            this.logEntryEvent.RecordSObjectTypeNamespace__c = getSObjectTypeNamespace(record.getSObjectType());
        }

        return this;
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  records The list of `SObject` records related to the entry. The JSON of the list is automatically added to the entry
     * @return         The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setRecord(List<SObject> records) {
        if (this.shouldSave() == false) {
            return this;
        }

        this.logEntryEvent.RecordCollectionSize__c = records?.size();
        this.logEntryEvent.RecordCollectionType__c = 'List';

        Schema.SObjectType sobjectType = records?.getSObjectType();
        String recordJson = getJson(records, userSettings.IsRecordFieldStrippingEnabled__c);
        if (sobjectType == null) {
            this.logEntryEvent.RecordJson__c = recordJson;
            this.logEntryEvent.RecordSObjectClassification__c = 'Unknown';
            this.logEntryEvent.RecordSObjectType__c = 'Unknown';
        } else {
            String cleanedRecordJson = applyDataMaskRules(recordJson);
            Boolean recordJsonMasked = cleanedRecordJson != recordJson;

            this.logEntryEvent.RecordJson__c = cleanedRecordJson;
            this.logEntryEvent.RecordJsonMasked__c = recordJsonMasked;
            this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(sobjectType);
            this.logEntryEvent.RecordSObjectType__c = sobjectType.getDescribe().getName();
            this.logEntryEvent.RecordSObjectTypeNamespace__c = getSObjectTypeNamespace(sobjectType);
        }

        return this;
    }

    /**
     * @description Sets the log entry event's record fields
     * @param  recordIdToRecord The map of `SObject` records related to the entry. The JSON of the map is automatically added to the entry
     * @return                  The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setRecord(Map<Id, SObject> recordIdToRecord) {
        if (this.shouldSave == false) {
            return this;
        }

        this.logEntryEvent.RecordCollectionSize__c = recordIdToRecord?.size();
        this.logEntryEvent.RecordCollectionType__c = 'Map';

        List<SObject> recordsList = recordIdToRecord?.values();
        Schema.SObjectType sobjectType = recordIdToRecord?.size() > 0 ? recordsList.get(0)?.getSObjectType() : null;
        String recordJson = getJson(recordIdToRecord, userSettings.IsRecordFieldStrippingEnabled__c);
        if (sobjectType == null) {
            this.logEntryEvent.RecordJson__c = recordJson;
            this.logEntryEvent.RecordSObjectClassification__c = 'Unknown';
            this.logEntryEvent.RecordSObjectType__c = 'Unknown';
        } else {
            String cleanedRecordJson = applyDataMaskRules(recordJson);
            Boolean recordJsonMasked = cleanedRecordJson != recordJson;

            this.logEntryEvent.RecordJson__c = cleanedRecordJson;
            this.logEntryEvent.RecordJsonMasked__c = recordJsonMasked;
            this.logEntryEvent.RecordSObjectClassification__c = getSObjectClassification(sobjectType);
            this.logEntryEvent.RecordSObjectType__c = sobjectType.getDescribe().getName();
            this.logEntryEvent.RecordSObjectTypeNamespace__c = getSObjectTypeNamespace(sobjectType);
        }

        return this;
    }

    /**
     * @description Sets the log entry event's HTTP Request fields
     * @param  request The instance of `HttpRequest` to log
     * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setHttpRequestDetails(System.HttpRequest request) {
        if (this.shouldSave() == false || request == null) {
            return this;
        }

        String cleanedRequestBody = applyDataMaskRules(request.getBody());
        Boolean requestBodyMasked = cleanedRequestBody != request.getBody();

        this.logEntryEvent.HttpRequestBody__c = cleanedRequestBody;
        this.logEntryEvent.HttpRequestBodyMasked__c = requestBodyMasked;
        this.logEntryEvent.HttpRequestCompressed__c = request.getCompressed();
        this.logEntryEvent.HttpRequestEndpoint__c = request.getEndpoint();
        this.logEntryEvent.HttpRequestMethod__c = request.getMethod();
        return this;
    }

    /**
     * @description Sets the log entry event's HTTP Response fields
     * @param  response The instance of `HttpResponse` to log
     * @return              The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder setHttpResponseDetails(System.HttpResponse response) {
        if (this.shouldSave() == false || response == null) {
            return this;
        }

        String cleanedResponseBody = applyDataMaskRules(response.getBody());
        Boolean responseBodyMasked = cleanedResponseBody != response.getBody();

        String formattedHeadersString;
        if (LoggerParameter.STORE_HTTP_RESPONSE_HEADER_VALUES) {
            List<String> headers = new List<String>();
            for (String headerKey : response.getHeaderKeys()) {
                headers.add(String.format(HTTP_HEADER_FORMAT, new List<String>{ headerKey, response.getHeader(headerKey) }));
            }
            formattedHeadersString = String.join(headers, NEW_LINE_DELIMITER);
        }
        this.logEntryEvent.HttpResponseBody__c = cleanedResponseBody;
        this.logEntryEvent.HttpResponseBodyMasked__c = responseBodyMasked;
        this.logEntryEvent.HttpResponseHeaderKeys__c = String.join(response.getHeaderKeys(), NEW_LINE_DELIMITER);
        this.logEntryEvent.HttpResponseHeaders__c = formattedHeadersString;
        this.logEntryEvent.HttpResponseStatus__c = response.getStatus();
        this.logEntryEvent.HttpResponseStatusCode__c = response.getStatusCode();
        return this;
    }

    /**
     * @description Appends the tag to the existing list of tags
     * @param tag The string to use as a tag for the current entry
     * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    global LogEntryEventBuilder addTag(String tag) {
        if (this.shouldSave() == false || String.isBlank(tag)) {
            return this;
        }

        this.tags.add(tag);
        this.tagDetailsAreSet = false;
        return this;
    }

    /**
     * @description Appends the tag to the existing list of tags
     * @param tags The list of strings to use as tags for the current entry
     * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
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
     * @param tags A list of tags
     * @return An instance of LogEntryEventBuilder with the given topics / tags.
     */
    public LogEntryEventBuilder setTopics(List<String> tags) {
        return this.addTags(tags);
    }

    /**
     * @description Parses the provided stack trace and sets the log entry's origin & stack trace fields
     * @param stackTraceString The Apex stack trace string to parse
     * @return The same instance of `LogEntryEventBuilder`, useful for chaining methods
     */
    @SuppressWarnings('PMD.NcssMethodCount')
    global LogEntryEventBuilder parseStackTrace(String stackTraceString) {
        if (LoggerParameter.ENABLE_STACK_TRACE_PARSING == false || this.shouldSave() == false || isValidStackTrace(stackTraceString) == false) {
            return this;
        }

        List<String> stackTraceLines = new List<String>();
        String previousStackTraceLine;
        for (String currentStackTraceLine : stackTraceString.split(NEW_LINE_DELIMITER)) {
            // Duplicate lines are sometimes introduced, so skip the current line if it's the same as the previous line
            if (currentStackTraceLine == previousStackTraceLine) {
                continue;
            }

            // Don't include the logging system's classes in the stack trace
            Boolean ignoreLine = false;
            for (String ignoredApexClass : this.ignoredApexClasses) {
                if (currentStackTraceLine.contains('.' + ignoredApexClass.trim() + '.')) {
                    ignoreLine = true;
                    continue;
                }
            }
            // Some lines, especially in the managed package, can result in '()' or '(Nebula)'
            if (isValidStackTrace(currentStackTraceLine) == false) {
                ignoreLine = true;
            }

            if (ignoreLine == false) {
                previousStackTraceLine = currentStackTraceLine;
                stackTraceLines.add(currentStackTraceLine);
            }
        }

        // In a managed package, we can end up with an invalid (unhelpful) stack trace, so only store when valid
        stackTraceString = String.join(stackTraceLines, NEW_LINE_DELIMITER);
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
     * @return A boolean set to true if the log entries should be saved.
     */
    public Boolean shouldSave() {
        return this.shouldSave;
    }

    /**
     * @description Returns the `LogEntryEvent__e` record for this instance of LogEntryEventBuilder
     * @return The `LogEntryEvent__e` record
     */
    global LogEntryEvent__e getLogEntryEvent() {
        if (this.shouldSave() == false) {
            return null;
        }

        // Lazy-loading of some details to help minimize Apex heap size usage until needed
        if (this.detailsAreSet == false) {
            for (String fieldName : LOG_ENTRY_EVENT_TEMPLATE.getPopulatedFieldsAsMap().keySet()) {
                this.logEntryEvent.put(fieldName, LOG_ENTRY_EVENT_TEMPLATE.get(fieldName));
            }
            if (this.userSettings.IsAnonymousModeEnabled__c == false) {
                setUserInfoDetails(this.logEntryEvent);
                setQueriedAuthSessionDetails(this.logEntryEvent, this.userSettings);
                setQueriedUserDetails(this.logEntryEvent, this.userSettings);
            }
            setQueriedNetworkDetails(this.logEntryEvent, this.userSettings);
            setQueriedOrganizationDetails(this.logEntryEvent, this.userSettings);
            this.detailsAreSet = true;
        }

        // getLogEntryEvent() and addTag() could both be called multiple times
        // for the same instance of LogEntryBuilder, so tags are set (if needed)
        // each time getLogEntryEvent() is called, whereas methods executed above (using Boolean
        // this.detailsAreSet) only need to be run once
        if (this.tagDetailsAreSet == false) {
            this.setTagsDetails();
            this.tagDetailsAreSet = true;
        }

        // Salesforce does not provide precise datetimes in Apex triggers for platform events
        // Set the string value of timestamp to a second field as a workaround
        // See https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_api_considerations.htm
        if (this.logEntryEvent.Timestamp__c != null) {
            this.logEntryEvent.TimestampString__c = String.valueOf(this.logEntryEvent.Timestamp__c.getTime());
        }

        return this.logEntryEvent;
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private void logToApexDebug(String message) {
        if (this.userSettings.IsApexSystemDebugLoggingEnabled__c == false) {
            return;
        }

        String template = LoggerParameter.SYSTEM_DEBUG_MESSAGE_FORMAT?.unescapeJava();
        if (String.isNotBlank(template)) {
            List<String> possibleReplacements = template.split('\\{');
            for (String possibleReplacement : possibleReplacements) {
                if (String.isBlank(possibleReplacement)) {
                    continue;
                }
                String logEntryFieldName = possibleReplacement.substringBefore('}');
                Object logEntryFieldValue = this.logEntryEvent.get(logEntryFieldName);
                if (logEntryFieldValue == null) {
                    logEntryFieldValue = '(null)';
                }
                template = template.replace('{' + logEntryFieldName + '}', String.valueOf(logEntryFieldValue));
            }
            this.debugMessage = template;
        } else {
            this.debugMessage = message;
        }

        // One of a few limited places in the codebase (except tests) that should use System.debug()
        // The rest of the codebase should use a method in Logger.cls
        System.debug(this.entryLoggingLevel, this.debugMessage);
    }

    private void parseStackTrace() {
        if (LoggerParameter.ENABLE_STACK_TRACE_PARSING == false) {
            return;
        }

        System.DmlException stackTraceException = new System.DmlException();
        this.parseStackTrace(stackTraceException.getStackTraceString());
    }

    private void setTagsDetails() {
        if (this.tags.isEmpty() || this.tagDetailsAreSet) {
            return;
        }

        List<String> sortedTags = new List<String>(this.tags);
        sortedTags.sort();
        this.logEntryEvent.Tags__c = String.escapeSingleQuotes(String.join(sortedTags, NEW_LINE_DELIMITER));
    }

    private static LogEntryEvent__e getLogEntryEventTemplate() {
        LogEntryEvent__e templateLogEntryEvent = new LogEntryEvent__e(
            LimitsAggregateQueriesMax__c = System.Limits.getLimitAggregateQueries(),
            LimitsAsyncCallsMax__c = System.Limits.getLimitAsyncCalls(),
            LimitsCalloutsMax__c = System.Limits.getLimitCallouts(),
            LimitsCpuTimeMax__c = System.Limits.getLimitCpuTime(),
            LimitsDmlRowsMax__c = System.Limits.getLimitDmlRows(),
            LimitsDmlStatementsMax__c = System.Limits.getLimitDmlStatements(),
            LimitsEmailInvocationsMax__c = System.Limits.getLimitEmailInvocations(),
            LimitsFutureCallsMax__c = System.Limits.getLimitFutureCalls(),
            LimitsHeapSizeMax__c = System.Limits.getLimitHeapSize(),
            LimitsMobilePushApexCallsMax__c = System.Limits.getLimitMobilePushApexCalls(),
            LimitsPublishImmediateDmlStatementsMax__c = System.Limits.getLimitPublishImmediateDML(),
            LimitsQueueableJobsMax__c = System.Limits.getLimitQueueableJobs(),
            LimitsSoqlQueriesMax__c = System.Limits.getLimitQueries(),
            LimitsSoqlQueryLocatorRowsMax__c = System.Limits.getLimitQueryLocatorRows(),
            LimitsSoqlQueryRowsMax__c = System.Limits.getLimitQueryRows(),
            LimitsSoslSearchesMax__c = System.Limits.getLimitSoslQueries()
        );

        return templateLogEntryEvent;
    }

    private static void setQueriedAuthSessionDetails(LogEntryEvent__e logEntryEvent, LoggerSettings__c userSettings) {
        if (userSettings.IsEnabled__c == false || LoggerParameter.QUERY_AUTH_SESSION_DATA_SYNCHRONOUSLY == false) {
            return;
        }

        LoggerSObjectProxy.AuthSession cachedAuthSessionProxy = LoggerEngineDataSelector.getInstance().getCachedAuthSessionProxy();
        if (cachedAuthSessionProxy == null) {
            return;
        }

        logEntryEvent.LoginApplication__c = cachedAuthSessionProxy.LoginHistory.Application;
        logEntryEvent.LoginBrowser__c = cachedAuthSessionProxy.LoginHistory.Browser;
        logEntryEvent.LoginHistoryId__c = cachedAuthSessionProxy.LoginHistoryId;
        logEntryEvent.LoginPlatform__c = cachedAuthSessionProxy.LoginHistory.Platform;
        logEntryEvent.LoginType__c = cachedAuthSessionProxy.LoginType;
        logEntryEvent.LogoutUrl__c = cachedAuthSessionProxy.LogoutUrl;
        logEntryEvent.SessionId__c = cachedAuthSessionProxy.Id;
        logEntryEvent.SessionSecurityLevel__c = cachedAuthSessionProxy.SessionSecurityLevel;
        logEntryEvent.SessionType__c = cachedAuthSessionProxy.SessionType;
        logEntryEvent.SourceIp__c = cachedAuthSessionProxy.SourceIp;

        if (cachedAuthSessionProxy.LoginHistory.UserId != CURRENT_USER.Id) {
            logEntryEvent.ImpersonatedById__c = cachedAuthSessionProxy.LoginHistory.UserId;
        }
    }

    private static void setQueriedNetworkDetails(LogEntryEvent__e logEntryEvent, LoggerSettings__c userSettings) {
        if (userSettings.IsEnabled__c == false || LoggerParameter.QUERY_NETWORK_DATA_SYNCHRONOUSLY == false || String.isBlank(networkId)) {
            return;
        }

        logEntryEvent.NetworkId__c = networkId;
        LoggerSObjectProxy.Network cachedNetworkProxy = LoggerEngineDataSelector.getInstance().getCachedNetworkProxy(networkId);
        if (cachedNetworkProxy == null) {
            return;
        }

        logEntryEvent.NetworkLoginUrl__c = System.Network.getLoginUrl(cachedNetworkProxy.Id);
        logEntryEvent.NetworkLogoutUrl__c = System.Network.getLogoutUrl(cachedNetworkProxy.Id);
        logEntryEvent.NetworkName__c = cachedNetworkProxy.Name;
        logEntryEvent.NetworkSelfRegistrationUrl__c = System.Network.getSelfRegUrl(cachedNetworkProxy.Id);
        logEntryEvent.NetworkUrlPathPrefix__c = cachedNetworkProxy.UrlPathPrefix;
    }

    private static void setQueriedOrganizationDetails(LogEntryEvent__e logEntryEvent, LoggerSettings__c userSettings) {
        if (userSettings.IsEnabled__c == false || LoggerParameter.QUERY_ORGANIZATION_DATA_SYNCHRONOUSLY == false) {
            return;
        }

        Organization cachedOrganization = LoggerEngineDataSelector.getInstance().getCachedOrganization();
        if (cachedOrganization == null) {
            return;
        }

        logEntryEvent.OrganizationEnvironmentType__c = getOrganizationEnvironmentType(userSettings);
        logEntryEvent.OrganizationId__c = cachedOrganization?.Id;
        logEntryEvent.OrganizationInstanceName__c = cachedOrganization?.InstanceName;
        logEntryEvent.OrganizationName__c = cachedOrganization?.Name;
        logEntryEvent.OrganizationNamespacePrefix__c = cachedOrganization?.NamespacePrefix;
        logEntryEvent.OrganizationType__c = cachedOrganization?.OrganizationType;
    }

    private static void setQueriedUserDetails(LogEntryEvent__e logEntryEvent, LoggerSettings__c userSettings) {
        if (userSettings.IsEnabled__c == false || LoggerParameter.QUERY_USER_DATA_SYNCHRONOUSLY == false) {
            return;
        }

        User cachedUser = LoggerEngineDataSelector.getInstance().getCachedUser();
        if (cachedUser == null) {
            return;
        }

        logEntryEvent.LoggedByUsername__c = cachedUser.Username;
        logEntryEvent.ProfileName__c = cachedUser.Profile.Name;
        logEntryEvent.UserLicenseDefinitionKey__c = cachedUser.Profile.UserLicense.LicenseDefinitionKey;
        logEntryEvent.UserLicenseId__c = cachedUser.Profile.UserLicenseId;
        logEntryEvent.UserLicenseName__c = cachedUser.Profile.UserLicense.Name;
        logEntryEvent.UserRoleName__c = cachedUser.UserRole?.Name;
    }

    private static void setUserInfoDetails(LogEntryEvent__e templateLogEntryEvent) {
        templateLogEntryEvent.Locale__c = System.UserInfo.getLocale();
        templateLogEntryEvent.LoggedById__c = System.UserInfo.getUserId();
        templateLogEntryEvent.ProfileId__c = System.UserInfo.getProfileId();
        templateLogEntryEvent.ThemeDisplayed__c = System.UserInfo.getUiThemeDisplayed();
        templateLogEntryEvent.TimeZoneId__c = System.UserInfo.getTimeZone().getId();
        templateLogEntryEvent.TimeZoneName__c = System.UserInfo.getTimeZone().getDisplayName();
        templateLogEntryEvent.UserRoleId__c = System.UserInfo.getUserRoleId();
        templateLogEntryEvent.UserType__c = System.UserInfo.getUserType();
    }

    // Private static helper methods
    @TestVisible
    private static void setMockDataMaskRule(LogEntryDataMaskRule__mdt dataMaskRule) {
        CACHED_DATA_MASK_RULES.put(dataMaskRule.DeveloperName, dataMaskRule);
    }

    private String applyDataMaskRules(String dataInput) {
        if (this.userSettings.IsDataMaskingEnabled__c == false || String.isBlank(dataInput)) {
            return dataInput;
        }

        for (LogEntryDataMaskRule__mdt dataMaskRule : CACHED_DATA_MASK_RULES.values()) {
            if (dataMaskRule.IsEnabled__c) {
                dataInput = dataInput.replaceAll(dataMaskRule.SensitiveDataRegEx__c, dataMaskRule.ReplacementRegEx__c);
            }
        }
        return dataInput;
    }

    private static String getJson(SObject record, Boolean isRecordFieldStrippingEnabled) {
        List<SObject> records = new List<SObject>{ record };
        records = isRecordFieldStrippingEnabled == false ? records : stripInaccessible(records);

        if (records == null) {
            return null;
        }

        SObject strippedRecord = records.get(0);
        return truncateFieldValue(Schema.LogEntryEvent__e.RecordJson__c, JSON.serializePretty(strippedRecord));
    }

    private static String getJson(List<SObject> records, Boolean isRecordFieldStrippingEnabled) {
        records = isRecordFieldStrippingEnabled == false ? records : stripInaccessible(records);
        return truncateFieldValue(Schema.LogEntryEvent__e.RecordJson__c, JSON.serializePretty(records));
    }

    private static String getJson(Map<Id, SObject> recordIdToRecord, Boolean isRecordFieldStrippingEnabled) {
        if (recordIdToRecord == null) {
            return null;
        }

        // In Apex, a Map<Id, SObject> with a null ID value will break during serialization,
        // so convert it to a Map<String, SObject> first
        Map<String, SObject> strippedRecordIdToRecord = new Map<String, SObject>();
        for (Id recordId : recordIdToRecord.keySet()) {
            SObject record = recordIdToRecord.get(recordId);
            // Record field-stripping isn't done by reference, so the record has to be reassigned
            record = isRecordFieldStrippingEnabled == false ? record : stripInaccessible(record);
            String recordIdString = recordId == null ? '' : recordId;
            strippedRecordIdToRecord.put(recordIdString, record);
        }
        return truncateFieldValue(Schema.LogEntryEvent__e.RecordJson__c, JSON.serializePretty(strippedRecordIdToRecord));
    }

    private static String getOrganizationEnvironmentType(LoggerSettings__c userSettings) {
        if (cachedOrganizationEnvironmentType != null) {
            return cachedOrganizationEnvironmentType;
        }

        if (userSettings.IsEnabled__c == false || LoggerParameter.QUERY_ORGANIZATION_DATA_SYNCHRONOUSLY == false) {
            return '';
        }

        Organization cachedOrganization = LoggerEngineDataSelector.getInstance().getCachedOrganization();
        String cachedOrganizationEnvironmentType;
        if (cachedOrganization == null) {
            cachedOrganizationEnvironmentType = '';
        } else if (cachedOrganization.IsSandbox && cachedOrganization.TrialExpirationDate != null) {
            cachedOrganizationEnvironmentType = 'Scratch Org';
        } else if (cachedOrganization.IsSandbox) {
            cachedOrganizationEnvironmentType = 'Sandbox';
        } else {
            cachedOrganizationEnvironmentType = 'Production';
        }
        return cachedOrganizationEnvironmentType;
    }

    private static String getNamespacePrefix() {
        String className = LogEntryEventBuilder.class.getName();
        String namespacePrefix = className.contains('.') ? className.substringBefore('.') : '';

        return namespacePrefix;
    }

    private static String getSObjectClassification(Schema.SObjectType sobjectType) {
        String sobjectName = sobjectType.getDescribe().getName();

        // Check the map to see if we've already determined the classification for this SObject type
        if (CACHED_SOBJECT_NAME_TO_CLASSIFICATION.containsKey(sobjectName)) {
            return CACHED_SOBJECT_NAME_TO_CLASSIFICATION.get(sobjectName);
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
        CACHED_SOBJECT_NAME_TO_CLASSIFICATION.put(sobjectName, sobjectClassification);

        return sobjectClassification;
    }

    private static Map<String, String> getSObjectSuffixToClassification() {
        // TODO add sample metadata for external object + picklist value + test
        // Example: MyExternalObject__x
        // '__x' => 'External Object'

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

    private static Map<String, LogEntryDataMaskRule__mdt> loadDataMaskRules() {
        Map<String, LogEntryDataMaskRule__mdt> activeDataMaskRules = new Map<String, LogEntryDataMaskRule__mdt>();
        for (LogEntryDataMaskRule__mdt dataMaskRule : LogEntryDataMaskRule__mdt.getAll().values()) {
            if (dataMaskRule.IsEnabled__c) {
                activeDataMaskRules.put(dataMaskRule.DeveloperName, dataMaskRule);
            }
        }
        if (System.Test.isRunningTest()) {
            // Tests shouldn't rely on the actual CMDT rules in the org
            // Clear the org's loaded records during tests, and mock via setMockDataMaskRule()
            activeDataMaskRules.clear();
        }
        return activeDataMaskRules;
    }

    private static SObject stripInaccessible(SObject record) {
        return stripInaccessible(new List<SObject>{ record }).get(0);
    }

    private static List<SObject> stripInaccessible(List<SObject> records) {
        if (records == null || records.isEmpty() || records.get(0).getSObjectType() == Schema.AggregateResult.SObjectType) {
            return records;
        }

        System.SObjectAccessDecision securityDecision = System.Security.stripInaccessible(System.AccessType.READABLE, records, false);
        return securityDecision.getRecords();
    }

    private static String truncateFieldValue(Schema.SObjectField field, String value) {
        Integer fieldMaxLength = field.getDescribe().getLength();
        return value?.left(fieldMaxLength);
    }
}
