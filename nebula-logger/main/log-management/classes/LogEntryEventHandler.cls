//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description Processes `LogEntryEvent__e` platform events and normalizes the data into `Log__c` and `LogEntry__c` records
 */
public without sharing class LogEntryEventHandler extends LoggerSObjectHandler {
    private static final Map<String, Log__c> TRANSACTION_ID_TO_LOG = new Map<String, Log__c>();
    @TestVisible
    private static final Boolean TAGGING_IS_ENABLED = LoggerParameter.Handler.getBoolean('LogEntryEventHandler_EnableTagging', true);
    @TestVisible
    private static final Boolean TAG_USING_TOPICS = LoggerParameter.Handler.getBoolean('LogEntryEventHandler_UseTopicsForTags', false);
    @TestVisible
    private static final List<LogEntryTagRule__mdt> TAG_ASSIGNMENT_RULES = getTagAssignmentRules();

    // Trigger-based variables - tests can override these with mock objects
    @TestVisible
    private List<LogEntryEvent__e> logEntryEvents {
        get {
            return (List<LogEntryEvent__e>) this.triggerNew;
        }
    }

    private Boolean shouldCallStatusApi = LoggerParameter.Handler.getBoolean('LogEntryEventHandler_CallStatusApi', false);
    private List<LogEntry__c> logEntries = new List<LogEntry__c>();
    private Map<String, List<String>> logEntryEventUuidToTagNames = new Map<String, List<String>>();
    private Set<String> tagNames = new Set<String>();

    public LogEntryEventHandler() {
    }

    public LogEntryEventHandler(TriggerOperation triggerOperationType, List<LogEntryEvent__e> logEntryEvents) {
        // Override the variables provided by LoggerSObjectHandler
        this.triggerOperationType = triggerOperationType;
        this.triggerNew = logEntryEvents;
    }

    /**
     * @description Returns SObject Type that the handler is responsible for processing
     * @return      The instance of `SObjectType`
     */
    public override SObjectType getSObjectType() {
        return Schema.LogEntryEvent__e.SObjectType;
    }

    /**
     * @description Runs the trigger handler's logic for the `LogEntryEvent__e` platform event object
     */
    public override void execute() {
        if (this.isEnabled() == false) {
            return;
        }

        switch on this.triggerOperationType {
            when AFTER_INSERT {
                this.upsertLogs();
                this.generateLogEntries();
                this.setApexClassFields();
                this.setFlowDefinitionFields();
                this.setFlowVersionFields();
                this.setFlowInterviewFields();
                this.insertLogEntries();
                this.appendRuleBasedTags();
                this.insertLogEntryTags();
            }
        }

        this.executePlugins();
    }

    private void upsertLogs() {
        // To avoid making a callout for every log for details retrieved from api.status.salesforce.com,
        // ...try to query recent logs first to see if there is a recent log with the details already populated
        Log__c recentLogWithApiReleaseDetails = getRecentLogWithApiReleaseDetails();

        // The LogEntryEvent__e object stores a denormalized version of Log__c & LogEntry__c data
        // In case the list contains entries tied to multiple transactions, use the TRANSACTION_ID_TO_LOG map to create 1 Log__c per transaction ID

        for (LogEntryEvent__e logEntryEvent : this.logEntryEvents) {
            if (TRANSACTION_ID_TO_LOG.containsKey(logEntryEvent.TransactionId__c) == true) {
                continue;
            }

            Log__c parentLog = new Log__c(TransactionId__c = logEntryEvent.ParentLogTransactionId__c);
            Log__c log = new Log__c();

            // Guest users cannot own records, so keep the log owner as the current user (Automated Process)
            String guestUserLicenseName = 'Guest User License';
            Id logOwnerId;
            if (logEntryEvent.UserLicenseName__c == guestUserLicenseName || String.isBlank(logEntryEvent.CreatedById)) {
                logOwnerId = UserInfo.getUserId();
            } else {
                logOwnerId = logEntryEvent.CreatedById;
            }

            if (recentLogWithApiReleaseDetails != null) {
                log.ApiReleaseNumber__c = recentLogWithApiReleaseDetails.ApiReleaseNumber__c;
                log.ApiReleaseVersion__c = recentLogWithApiReleaseDetails.ApiReleaseVersion__c;
            }

            log.ApiVersion__c = logEntryEvent.ApiVersion__c;
            log.Locale__c = logEntryEvent.Locale__c;
            log.LoggedBy__c = logEntryEvent.LoggedById__c;
            log.LoggedByUsername__c = logEntryEvent.LoggedByUsername__c;
            log.LoginDomain__c = logEntryEvent.LoginDomain__c;
            log.LoginHistoryId__c = logEntryEvent.LoginHistoryId__c;
            log.LoginApplication__c = logEntryEvent.LoginApplication__c;
            log.LoginBrowser__c = logEntryEvent.LoginBrowser__c;
            log.LoginPlatform__c = logEntryEvent.LoginPlatform__c;
            log.LoginType__c = logEntryEvent.LoginType__c;
            log.LogoutUrl__c = logEntryEvent.LogoutUrl__c;
            log.NetworkId__c = logEntryEvent.NetworkId__c;
            log.NetworkLoginUrl__c = logEntryEvent.NetworkLoginUrl__c;
            log.NetworkLogoutUrl__c = logEntryEvent.NetworkLogoutUrl__c;
            log.NetworkName__c = logEntryEvent.NetworkName__c;
            log.NetworkSelfRegistrationUrl__c = logEntryEvent.NetworkSelfRegistrationUrl__c;
            log.NetworkUrlPathPrefix__c = logEntryEvent.NetworkUrlPathPrefix__c;
            log.OrganizationDomainUrl__c = logEntryEvent.OrganizationDomainUrl__c;
            log.OrganizationEnvironmentType__c = logEntryEvent.OrganizationEnvironmentType__c;
            log.OrganizationId__c = logEntryEvent.OrganizationId__c;
            log.OrganizationInstanceName__c = logEntryEvent.OrganizationInstanceName__c;
            log.OrganizationName__c = logEntryEvent.OrganizationName__c;
            log.OrganizationNamespacePrefix__c = logEntryEvent.OrganizationNamespacePrefix__c;
            log.OrganizationType__c = logEntryEvent.OrganizationType__c;
            log.OwnerId = logOwnerId;
            log.ParentLog__r = logEntryEvent.ParentLogTransactionId__c == null ? null : parentLog;
            log.ProfileId__c = logEntryEvent.ProfileId__c;
            log.ProfileName__c = logEntryEvent.ProfileName__c;
            log.SessionId__c = logEntryEvent.SessionId__c;
            log.SessionSecurityLevel__c = logEntryEvent.SessionSecurityLevel__c;
            log.SessionType__c = logEntryEvent.SessionType__c;
            log.SourceIp__c = logEntryEvent.SourceIp__c;
            log.SystemMode__c = logEntryEvent.SystemMode__c;
            log.ThemeDisplayed__c = logEntryEvent.ThemeDisplayed__c;
            log.TimeZoneId__c = logEntryEvent.TimeZoneId__c;
            log.TimeZoneName__c = logEntryEvent.TimeZoneName__c;
            log.TransactionId__c = logEntryEvent.TransactionId__c;
            log.UserLicenseDefinitionKey__c = logEntryEvent.UserLicenseDefinitionKey__c;
            log.UserLicenseId__c = logEntryEvent.UserLicenseId__c;
            log.UserLicenseName__c = logEntryEvent.UserLicenseName__c;
            log.UserLoggingLevel__c = logEntryEvent.UserLoggingLevel__c;
            log.UserLoggingLevelOrdinal__c = logEntryEvent.UserLoggingLevelOrdinal__c;
            log.UserRoleId__c = logEntryEvent.UserRoleId__c;
            log.UserRoleName__c = logEntryEvent.UserRoleName__c;
            log.UserType__c = logEntryEvent.UserType__c;

            TRANSACTION_ID_TO_LOG.put(log.TransactionId__c, log);
        }

        upsert TRANSACTION_ID_TO_LOG.values() Schema.Log__c.TransactionId__c;

        // If no recent logs have the details, and there is not another instance of the job in progress, then start a new one
        if (this.shouldCallStatusApi == true && recentLogWithApiReleaseDetails == null && getCountOfOpenJobs() == 0) {
            setStatusApiDetails();
        }
    }

    private void generateLogEntries() {
        for (LogEntryEvent__e logEntryEvent : this.logEntryEvents) {
            // Workaround field for platform issue w/ accurate datetimes
            Datetime timestamp = String.isNotBlank(logEntryEvent.TimestampString__c)
                ? Datetime.valueOf(Long.valueOf(logEntryEvent.TimestampString__c))
                : logEntryEvent.Timestamp__c;

            LogEntry__c logEntry = new LogEntry__c(
                DatabaseResultCollectionType__c = logEntryEvent.DatabaseResultCollectionType__c,
                DatabaseResultJson__c = logEntryEvent.DatabaseResultJson__c,
                DatabaseResultType__c = logEntryEvent.DatabaseResultType__c,
                EpochTimestamp__c = logEntryEvent.EpochTimestamp__c,
                EventUuid__c = logEntryEvent.EventUuid,
                ExceptionMessage__c = logEntryEvent.ExceptionMessage__c,
                ExceptionStackTrace__c = logEntryEvent.ExceptionStackTrace__c,
                ExceptionType__c = logEntryEvent.ExceptionType__c,
                LimitsAggregateQueriesMax__c = logEntryEvent.LimitsAggregateQueriesMax__c,
                LimitsAggregateQueriesUsed__c = logEntryEvent.LimitsAggregateQueriesUsed__c,
                LimitsAsyncCallsMax__c = logEntryEvent.LimitsAsyncCallsMax__c,
                LimitsAsyncCallsUsed__c = logEntryEvent.LimitsAsyncCallsUsed__c,
                LimitsCalloutsMax__c = logEntryEvent.LimitsCalloutsMax__c,
                LimitsCalloutsUsed__c = logEntryEvent.LimitsCalloutsUsed__c,
                LimitsCpuTimeMax__c = logEntryEvent.LimitsCpuTimeMax__c,
                LimitsCpuTimeUsed__c = logEntryEvent.LimitsCpuTimeUsed__c,
                LimitsDmlRowsMax__c = logEntryEvent.LimitsDmlRowsMax__c,
                LimitsDmlRowsUsed__c = logEntryEvent.LimitsDmlRowsUsed__c,
                LimitsDmlStatementsMax__c = logEntryEvent.LimitsDmlStatementsMax__c,
                LimitsDmlStatementsUsed__c = logEntryEvent.LimitsDmlStatementsUsed__c,
                LimitsEmailInvocationsMax__c = logEntryEvent.LimitsEmailInvocationsMax__c,
                LimitsEmailInvocationsUsed__c = logEntryEvent.LimitsEmailInvocationsUsed__c,
                LimitsFutureCallsMax__c = logEntryEvent.LimitsFutureCallsMax__c,
                LimitsFutureCallsUsed__c = logEntryEvent.LimitsFutureCallsUsed__c,
                LimitsHeapSizeMax__c = logEntryEvent.LimitsHeapSizeMax__c,
                LimitsHeapSizeUsed__c = logEntryEvent.LimitsHeapSizeUsed__c,
                LimitsMobilePushApexCallsMax__c = logEntryEvent.LimitsMobilePushApexCallsMax__c,
                LimitsMobilePushApexCallsUsed__c = logEntryEvent.LimitsMobilePushApexCallsUsed__c,
                LimitsQueueableJobsMax__c = logEntryEvent.LimitsQueueableJobsMax__c,
                LimitsQueueableJobsUsed__c = logEntryEvent.LimitsQueueableJobsUsed__c,
                LimitsSoqlQueriesMax__c = logEntryEvent.LimitsSoqlQueriesMax__c,
                LimitsSoqlQueriesUsed__c = logEntryEvent.LimitsSoqlQueriesUsed__c,
                LimitsSoqlQueryLocatorRowsMax__c = logEntryEvent.LimitsSoqlQueryLocatorRowsMax__c,
                LimitsSoqlQueryLocatorRowsUsed__c = logEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c,
                LimitsSoqlQueryRowsMax__c = logEntryEvent.LimitsSoqlQueryRowsMax__c,
                LimitsSoqlQueryRowsUsed__c = logEntryEvent.LimitsSoqlQueryRowsUsed__c,
                LimitsSoslSearchesMax__c = logEntryEvent.LimitsSoslSearchesMax__c,
                LimitsSoslSearchesUsed__c = logEntryEvent.LimitsSoslSearchesUsed__c,
                Log__c = TRANSACTION_ID_TO_LOG.get(logEntryEvent.TransactionId__c).Id,
                LoggingLevel__c = logEntryEvent.LoggingLevel__c,
                LoggingLevelOrdinal__c = logEntryEvent.LoggingLevelOrdinal__c,
                Message__c = logEntryEvent.Message__c,
                MessageTruncated__c = logEntryEvent.MessageTruncated__c,
                Name = null, // Salesforce will auto-set the record ID as the name when null
                OriginLocation__c = logEntryEvent.OriginLocation__c,
                OriginType__c = logEntryEvent.OriginType__c,
                RecordCollectionType__c = logEntryEvent.RecordCollectionType__c,
                RecordId__c = logEntryEvent.RecordId__c,
                RecordJson__c = logEntryEvent.RecordJson__c,
                RecordSObjectClassification__c = logEntryEvent.RecordSObjectClassification__c,
                RecordSObjectType__c = logEntryEvent.RecordSObjectType__c,
                RecordSObjectTypeNamespace__c = logEntryEvent.RecordSObjectTypeNamespace__c,
                StackTrace__c = logEntryEvent.StackTrace__c,
                Timestamp__c = timestamp,
                TransactionEntryNumber__c = logEntryEvent.TransactionEntryNumber__c,
                TriggerIsExecuting__c = logEntryEvent.TriggerIsExecuting__c,
                TriggerOperationType__c = logEntryEvent.TriggerOperationType__c,
                TriggerSObjectType__c = logEntryEvent.TriggerSObjectType__c
            );

            this.logEntries.add(logEntry);
            if (logEntryEvent.Tags__c != null) {
                List<String> logEntryTagNames = getTagNames(logEntryEvent.Tags__c);

                this.tagNames.addAll(logEntryTagNames);
                this.logEntryEventUuidToTagNames.put(logEntry.EventUuid__c, logEntryTagNames);
            }
        }
    }

    private void setApexClassFields() {
        List<String> apexClassNames = new List<String>();
        List<LogEntry__c> apexLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (logEntry.OriginType__c == 'Apex') {
                // OriginLocation__c contains the class name + method name. Examples:
                // MyClass.someMethod
                // MyClass.MyInnerClass.someMethod
                String apexClassName = logEntry.OriginLocation__c.substringBefore('.');
                apexClassNames.add(apexClassName);
                apexLogEntries.add(logEntry);
            }
        }

        if (apexClassNames.isEmpty() == true) {
            return;
        }

        Map<String, ApexClass> classNameToApexClass = new Map<String, ApexClass>();
        for (ApexClass apexClass : [
            SELECT ApiVersion, CreatedById, CreatedDate, Id, LastModifiedById, LastModifiedDate, Name
            FROM ApexClass
            WHERE Name IN :apexClassNames
        ]) {
            classNameToApexClass.put(apexClass.Name, apexClass);
        }

        for (LogEntry__c logEntry : apexLogEntries) {
            String apexClassName = logEntry.OriginLocation__c.substringBefore('.');
            ApexClass apexClass = classNameToApexClass.get(apexClassName);
            if (apexClass == null) {
                continue;
            }

            logEntry.ApexClassApiVersion__c = 'v' + apexClass.ApiVersion;
            // TODO confirm if there any issues with automated users (e.g., PackagePushJob uses a not-quite-a-user)
            // logEntry.ApexClassCreatedById__c = apexClass.CreatedById;
            logEntry.ApexClassCreatedDate__c = apexClass.CreatedDate;
            logEntry.ApexClassId__c = apexClass.Id;
            // TODO confirm if there any issues with automated users (e.g., PackagePushJob uses a not-quite-a-user)
            // logEntry.ApexClassLastModifiedById__c = apexClass.LastModifiedById;
            logEntry.ApexClassLastModifiedDate__c = apexClass.LastModifiedDate;
        }
    }

    private void setFlowDefinitionFields() {
        List<String> flowApiNames = new List<String>();
        List<LogEntry__c> flowLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (logEntry.OriginType__c == 'Flow') {
                flowApiNames.add(logEntry.OriginLocation__c);
                flowLogEntries.add(logEntry);
            }
        }

        if (flowApiNames.isEmpty() == true) {
            return;
        }

        Map<String, FlowDefinitionView> flowApiNameToDefinition = new Map<String, FlowDefinitionView>();
        for (
            FlowDefinitionView flowDefinition : [
                SELECT
                    ActiveVersionId,
                    ApiName,
                    Builder,
                    Description,
                    DurableId,
                    Label,
                    LastModifiedBy, // This is a text field of the person's name - it's NOT a lookup to User :'(
                    LastModifiedDate,
                    ManageableState,
                    ProcessType,
                    TriggerType
                FROM FlowDefinitionView
                WHERE ApiName IN :flowApiNames AND IsActive = TRUE
            ]
        ) {
            flowApiNameToDefinition.put(flowDefinition.ApiName, flowDefinition);
        }

        for (LogEntry__c logEntry : flowLogEntries) {
            FlowDefinitionView flowDefinition = flowApiNameToDefinition.get(logEntry.OriginLocation__c);
            if (flowDefinition == null) {
                continue;
            }

            logEntry.FlowActiveVersionId__c = flowDefinition.ActiveVersionId;
            logEntry.FlowBuilder__c = flowDefinition.Builder;
            logEntry.FlowDescription__c = flowDefinition.Description;
            logEntry.FlowDurableId__c = flowDefinition.DurableId;
            logEntry.FlowLabel__c = flowDefinition.Label;
            logEntry.FlowLastModifiedByName__c = flowDefinition.LastModifiedBy;
            logEntry.FlowLastModifiedDate__c = flowDefinition.LastModifiedDate;
            logEntry.FlowProcessType__c = flowDefinition.ProcessType;
            logEntry.FlowTriggerType__c = flowDefinition.TriggerType;
        }
    }

    private void setFlowVersionFields() {
        // https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowversionview.htm
        List<String> flowActiveVersionIds = new List<String>();
        List<LogEntry__c> flowLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (String.isNotBlank(logEntry.FlowActiveVersionId__c)) {
                flowActiveVersionIds.add(logEntry.FlowActiveVersionId__c);
                flowLogEntries.add(logEntry);
            }
        }

        if (flowActiveVersionIds.isEmpty() == true) {
            return;
        }

        Map<String, FlowVersionView> flowDurableId = new Map<String, FlowVersionView>();
        for (FlowVersionView flowVersionView : [
            SELECT ApiVersionRuntime, FlowDefinitionViewId, RunInMode, Status, VersionNumber
            FROM FlowVersionView
            WHERE DurableId IN :flowActiveVersionIds
        ]) {
            // Filtering on Status in SOQL seems to always return 0 results, so filter in code instead
            if (flowVersionView.Status == 'Active') {
                flowDurableId.put(flowVersionView.FlowDefinitionViewId, flowVersionView);
            }
        }

        for (LogEntry__c logEntry : flowLogEntries) {
            FlowVersionView flowVersionView = flowDurableId.get(logEntry.FlowDurableId__c);
            if (flowVersionView == null) {
                continue;
            }

            logEntry.FlowVersionApiVersionRuntime__c = 'v' + flowVersionView.ApiVersionRuntime + '.0';
            logEntry.FlowVersionRunInMode__c = flowVersionView.RunInMode;
            logEntry.FlowVersionNumber__c = flowVersionView.VersionNumber;
        }
    }

    private void setFlowInterviewFields() {
        // https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_flowversionview.htm
        List<String> flowInterviewGuids = new List<String>();
        List<LogEntry__c> flowLogEntries = new List<LogEntry__c>();
        for (LogEntry__c logEntry : this.logEntries) {
            if (String.isNotBlank(logEntry.FlowInterviewGuid__c)) {
                flowInterviewGuids.add(logEntry.FlowInterviewGuid__c);
                flowLogEntries.add(logEntry);
            }
        }

        if (flowInterviewGuids.isEmpty() == true) {
            return;
        }

        Map<String, FlowInterview> flowInterviewGuidToInterview = new Map<String, FlowInterview>();
        for (FlowInterview flowInterview : [SELECT CurrentElement, Guid, InterviewLabel, PauseLabel FROM FlowInterview WHERE Guid IN :flowInterviewGuids]) {
            flowInterviewGuidToInterview.put(flowInterview.Guid, flowInterview);
        }

        for (LogEntry__c logEntry : flowLogEntries) {
            FlowInterview flowInterview = flowInterviewGuidToInterview.get(logEntry.FlowDurableId__c);
            if (flowInterview == null) {
                continue;
            }

            logEntry.FlowInterviewCurrentElement__c = flowInterview.CurrentElement;
            logEntry.FlowInterviewLabel__c = flowInterview.InterviewLabel;
            logEntry.FlowInterviewPauseLabel__c = flowInterview.PauseLabel;
        }
    }

    private void insertLogEntries() {
        insert this.logEntries;
    }

    private void appendRuleBasedTags() {
        if (TAGGING_IS_ENABLED == false || TAG_ASSIGNMENT_RULES.isEmpty() == true) {
            return;
        }

        for (LogEntry__c logEntry : this.logEntries) {
            for (LogEntryTagRule__mdt rule : TAG_ASSIGNMENT_RULES) {
                Boolean ruleCriteriaMet = ruleCriteriaMet(logEntry, rule);

                if (ruleCriteriaMet == true) {
                    List<String> configuredTagNames = getTagNames(rule.Tags__c);
                    this.tagNames.addAll(configuredTagNames);
                    List<String> logEntryTags = logEntryEventUuidToTagNames.get(logEntry.EventUuid__c);
                    if (logEntryTags == null) {
                        logEntryTags = new List<String>();
                    }
                    logEntryTags.addAll(configuredTagNames);

                    this.logEntryEventUuidToTagNames.put(logEntry.EventUuid__c, logEntryTags);
                    this.tagNames.addAll(logEntryTags);
                }
            }
        }
    }

    private void insertLogEntryTags() {
        if (TAGGING_IS_ENABLED == false || this.tagNames.isEmpty()) {
            return;
        }

        // Orgs can be configured to either use LoggerTag__c & LogEntryTag__c (default), or use Topic & TopicAssignment
        Schema.SObjectType tagSObjectType = TAG_USING_TOPICS == true ? Topic.SObjectType : LoggerTag__c.SObjectType;
        Map<String, Id> tagNameToId = getTagNameToId(tagSObjectType);
        this.tagNames.addAll(tagNameToId.keySet());

        // Assign the tags to the records
        Set<SObject> tagAssignments = new Set<SObject>();
        for (LogEntry__c logEntry : this.logEntries) {
            List<String> logEntryTagNames = this.logEntryEventUuidToTagNames.get(logEntry.EventUuid__c);
            if (logEntryTagNames == null || logEntryEventUuidToTagNames.isEmpty()) {
                continue;
            }

            for (String tagName : logEntryTagNames) {
                if (TAG_USING_TOPICS == true) {
                    // Add the topic for the LogEntry__c & the parent Log__c
                    tagAssignments.add(new TopicAssignment(EntityId = logEntry.Id, TopicId = tagNameToId.get(tagName)));
                    tagAssignments.add(new TopicAssignment(EntityId = logEntry.Log__c, TopicId = tagNameToId.get(tagName)));
                } else {
                    // Add a LogEntryTag__c record that links to the LogEntry__c - the handler class will also related it to the parent Log__c
                    tagAssignments.add(new LogEntryTag__c(LogEntry__c = logEntry.Id, Tag__c = tagNameToId.get(tagName)));
                }
            }
        }
        insert new List<SObject>(tagAssignments);
    }

    private Map<String, Id> getTagNameToId(Schema.SObjectType tagSObjectType) {
        Map<String, Id> tagNameToId = new Map<String, Id>();

        String tagQuery = 'SELECT Id, Name FROM ' + tagSObjectType + ' WHERE Name IN :tagNames';
        for (SObject tag : Database.query(tagQuery)) {
            tagNameToId.put((String) tag.get('Name'), (Id) tag.get('Id'));
        }
        tagNameToId.putAll(this.insertMissingTags(tagSObjectType, tagNameToId));

        return tagNameToId;
    }

    private Map<String, Id> insertMissingTags(Schema.SObjectType tagSObjectType, Map<String, Id> existingTagNameToId) {
        Map<String, Id> missingTagNameToId = new Map<String, Id>();

        List<SObject> missingTagsToCreate = new List<SObject>();
        for (String tagName : this.tagNames) {
            if (existingTagNameToId.containsKey(tagName) == false) {
                SObject tag = tagSObjectType.newSObject();
                tag.put('Name', tagName);
                missingTagsToCreate.add(tag);
            }
        }

        if (!missingTagsToCreate.isEmpty()) {
            insert missingTagsToCreate;
            for (SObject tag : missingTagsToCreate) {
                missingTagNameToId.put((String) tag.get('Name'), (Id) tag.get('Id'));
            }
        }

        return missingTagNameToId;
    }

    // Private static methods
    private static List<String> getTagNames(String tagsString) {
        List<String> cleanedTagNames = new List<String>();

        for (String tagName : tagsString.split('\n')) {
            if (String.isNotBlank(tagName) == true) {
                cleanedTagNames.add(tagName.trim());
            }
        }

        return cleanedTagNames;
    }

    private static List<LogEntryTagRule__mdt> getTagAssignmentRules() {
        List<LogEntryTagRule__mdt> tagAssignmentRules = [
            SELECT Id, SObjectField__r.QualifiedApiName, ComparisonType__c, ComparisonValue__c, Tags__c
            FROM LogEntryTagRule__mdt
            WHERE IsEnabled__c = TRUE AND SObjectType__r.DeveloperName = 'LogEntry'
        ];
        for (LogEntryTagRule__mdt rule : tagAssignmentRules) {
            rule.SObjectField__c = rule.SObjectField__r.QualifiedApiName;
        }
        if (Test.isRunningTest() == true) {
            // During tests, only use mock records - tests can add mock records using LogEntryEventHandler.TAG_ASSIGNMENT_RULES.add()
            tagAssignmentRules.clear();
        }
        return tagAssignmentRules;
    }

    private static Boolean ruleCriteriaMet(LogEntry__c logEntry, LogEntryTagRule__mdt rule) {
        Boolean ruleCriteriaMet = false;
        String logEntryFieldValue = String.valueOf(logEntry.get(rule.SObjectField__c));
        String ruleComparisonValue = rule.ComparisonValue__c;

        switch on rule?.ComparisonType__c.toUpperCase() {
            when 'CONTAINS' {
                ruleCriteriaMet = logEntryFieldValue.containsIgnoreCase(ruleComparisonValue);
            }
            when 'EQUALS' {
                ruleCriteriaMet = logEntryFieldValue == ruleComparisonValue;
            }
            when 'MATCHES_REGEX' {
                ruleCriteriaMet = Pattern.compile(ruleComparisonValue).matcher(logEntryFieldValue).matches();
            }
            when 'STARTS_WITH' {
                ruleCriteriaMet = logEntryFieldValue.startsWith(ruleComparisonValue);
            }
        }

        return ruleCriteriaMet;
    }

    private static Log__c getRecentLogWithApiReleaseDetails() {
        // Query for recent logs created only today - the status API should be called
        // at least once per day to make sure that status details are still accurate.
        // This query should make a callout approximately every 4 hours.
        Datetime fourHoursAgo = System.now().addMinutes(-4 * 60);

        List<Log__c> logs = [
            SELECT Id, ApiReleaseNumber__c, ApiReleaseVersion__c
            FROM Log__c
            WHERE CreatedDate >= :fourHoursAgo AND CreatedDate = TODAY AND ApiReleaseNumber__c != NULL
            ORDER BY StartTime__c DESC
            LIMIT 1
        ];

        if (logs.isEmpty()) {
            return null;
        } else {
            return logs.get(0);
        }
    }

    private static Integer getCountOfOpenJobs() {
        return [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE
                ApexClass.Name = :LogEntryEventHandler.class.getName()
                AND MethodName = 'setStatusApiDetails'
                AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
        ];
    }

    @future(callout=true)
    private static void setStatusApiDetails() {
        System.debug('Running setStatusApiDetails()');

        Organization organization = [SELECT InstanceName FROM Organization];
        String statusApiEndpoint = 'https://api.status.salesforce.com/v1/instances/' + organization.InstanceName + '/status';

        HttpRequest request = new HttpRequest();
        request.setEndpoint(statusApiEndpoint);
        request.setMethod('GET');

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() >= 400) {
            String errorMessage =
                'Callout failed for ' +
                statusApiEndpoint +
                '\nReceived request status code ' +
                response.getStatusCode() +
                ', status message: ' +
                response.getStatus();
            throw new CalloutException(errorMessage);
        }

        StatusApiResponse statusApiResponse = (StatusApiResponse) JSON.deserialize(response.getBody(), StatusApiResponse.class);
        System.debug('statusApiResponse==' + statusApiResponse);

        List<Log__c> logsToUpdate = new List<Log__c>();
        for (Log__c log : [
            SELECT Id
            FROM Log__c
            WHERE CreatedDate = TODAY AND ApiReleaseNumber__c = NULL
            ORDER BY CreatedDate
            LIMIT :Limits.getLimitDmlRows()
        ]) {
            log.ApiReleaseNumber__c = statusApiResponse.releaseNumber;
            log.ApiReleaseVersion__c = statusApiResponse.releaseVersion;

            logsToUpdate.add(log);
        }
        System.debug('logsToUpdate==' + logsToUpdate);
        update logsToUpdate;
    }

    // Private class for handling the response from api.status.salesforce.com
    @TestVisible
    private class StatusApiResponse {
        public String releaseNumber { get; set; }
        public String releaseVersion { get; set; }
    }
}
