//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group log-management
 * @description Subscribes to `LogEntryEvent__e` platform events and normalizes the data into `Log__c` and `LogEntry__c` records
 */
public without sharing class LogEntryEventHandler {
    private static final Log__c LOG = new Log__c();

    private List<LogEntry__c> logEntries;
    private Map<LogEntry__c, List<String>> logEntryToTopics;
    private Set<String> topicNames;

    public LogEntryEventHandler() {
        this.logEntries = new List<LogEntry__c>();
        this.logEntryToTopics = new Map<LogEntry__c, List<String>>();
        this.topicNames = new Set<String>();
    }

    public void execute() {
        List<LogEntryEvent__e> logEntryEvents = (List<LogEntryEvent__e>) Trigger.new;

        switch on Trigger.operationType {
            when AFTER_INSERT {
                this.upsertLog(logEntryEvents);
                this.insertLogEntries(logEntryEvents);
                this.insertTopics();
            }
        }
    }

    private void upsertLog(List<LogEntryEvent__e> logEntryEvents) {
        if (LOG.Id != null) {
            return;
        }

        // The LogEntryEvent__e object stores a denormalized version of Log__c & LogEntry__c data
        // The first LogEntryEvent__e record is used to normalize the data
        LogEntryEvent__e logEntryEvent = logEntryEvents.get(0);
        Log__c parentLog = new Log__c(TransactionId__c = logEntryEvent.ParentLogTransactionId__c);

        LOG.ApiVersion__c = logEntryEvent.ApiVersion__c;
        LOG.Locale__c = logEntryEvent.Locale__c;
        LOG.LoggedBy__c = logEntryEvent.CreatedById;
        LOG.LoggedByUsername__c = logEntryEvent.LoggedByUsername__c;
        LOG.LoginDomain__c = logEntryEvent.LoginDomain__c;
        LOG.LoginHistoryId__c = logEntryEvent.LoginHistoryId__c;
        LOG.LoginApplication__c = logEntryEvent.LoginApplication__c;
        LOG.LoginBrowser__c = logEntryEvent.LoginBrowser__c;
        LOG.LoginPlatform__c = logEntryEvent.LoginPlatform__c;
        LOG.LoginType__c = logEntryEvent.LoginType__c;
        LOG.LogoutUrl__c = logEntryEvent.LogoutUrl__c;
        LOG.NetworkId__c = logEntryEvent.NetworkId__c;
        LOG.NetworkLoginUrl__c = logEntryEvent.NetworkLoginUrl__c;
        LOG.NetworkLogoutUrl__c = logEntryEvent.NetworkLogoutUrl__c;
        LOG.NetworkName__c = logEntryEvent.NetworkName__c;
        LOG.NetworkSelfRegistrationUrl__c = logEntryEvent.NetworkSelfRegistrationUrl__c;
        LOG.NetworkUrlPathPrefix__c = logEntryEvent.NetworkUrlPathPrefix__c;
        LOG.OrganizationDomainUrl__c = logEntryEvent.OrganizationDomainUrl__c;
        LOG.OrganizationEnvironmentType__c = logEntryEvent.OrganizationEnvironmentType__c;
        LOG.OrganizationId__c = logEntryEvent.OrganizationId__c;
        LOG.OrganizationInstanceName__c = logEntryEvent.OrganizationInstanceName__c;
        LOG.OrganizationName__c = logEntryEvent.OrganizationName__c;
        LOG.OrganizationNamespacePrefix__c = logEntryEvent.OrganizationNamespacePrefix__c;
        LOG.OrganizationType__c = logEntryEvent.OrganizationType__c;
        LOG.OwnerId = logEntryEvent.CreatedById;
        LOG.ParentLog__r = logEntryEvent.ParentLogTransactionId__c == null ? null : parentLog;
        LOG.ProfileId__c = logEntryEvent.ProfileId__c;
        LOG.ProfileName__c = logEntryEvent.ProfileName__c;
        LOG.SessionId__c = logEntryEvent.SessionId__c;
        LOG.SessionId__c = logEntryEvent.SessionId__c;
        LOG.SessionSecurityLevel__c = logEntryEvent.SessionSecurityLevel__c;
        LOG.SessionType__c = logEntryEvent.SessionType__c;
        LOG.SourceIp__c = logEntryEvent.SourceIp__c;
        LOG.SystemMode__c = logEntryEvent.SystemMode__c;
        LOG.ThemeDisplayed__c = logEntryEvent.ThemeDisplayed__c;
        LOG.TimeZoneId__c = logEntryEvent.TimeZoneId__c;
        LOG.TimeZoneName__c = logEntryEvent.TimeZoneName__c;
        LOG.TransactionId__c = logEntryEvent.TransactionId__c;
        LOG.UserLicenseDefinitionKey__c = logEntryEvent.UserLicenseDefinitionKey__c;
        LOG.UserLicenseId__c = logEntryEvent.UserLicenseId__c;
        LOG.UserLicenseName__c = logEntryEvent.UserLicenseName__c;
        LOG.UserLoggingLevel__c = logEntryEvent.UserLoggingLevel__c;
        LOG.UserLoggingLevelOrdinal__c = logEntryEvent.UserLoggingLevelOrdinal__c;
        LOG.UserRoleId__c = logEntryEvent.UserRoleId__c;
        LOG.UserRoleName__c = logEntryEvent.UserRoleName__c;
        LOG.UserType__c = logEntryEvent.UserType__c;

        // TODO cleanup
        // To avoid making a callout for every log, try to query recent logs first
        // If there are recent logs with the details already populated, copy the field values before upserting the log
        List<Log__c> recentLogsWithDetails = getRecentLogsWithDetails();
        if (recentLogsWithDetails.isEmpty() == false) {
            LOG.ApiReleaseNumber__c = recentLogsWithDetails.get(0).ApiReleaseNumber__c;
            LOG.ApiReleaseVersion__c = recentLogsWithDetails.get(0).ApiReleaseVersion__c;
        }

        upsert LOG TransactionId__c;

        // If no recent logs have the details, and there is not another instance of the job in progress, then start a new one
        if (recentLogsWithDetails.isEmpty() == true && getCountOfOpenJobs() == 0) {
            System.enqueueJob(new QueueableStatusApiCaller());
        }
    }

    private void insertLogEntries(List<LogEntryEvent__e> logEntryEvents) {
        if (LOG.Id == null) {
            return; // Avoid an exception - if there is no log, we can't save log entries
        }

        for (LogEntryEvent__e logEntryEvent : logEntryEvents) {
            // Workaround field for platform issue w/ accurate datetimes
            Datetime timestamp = String.isNotBlank(logEntryEvent.TimestampString__c)
                ? Datetime.valueOf(logEntryEvent.TimestampString__c)
                : logEntryEvent.Timestamp__c;

            LogEntry__c logEntry = new LogEntry__c(
                DatabaseResultJson__c = logEntryEvent.DatabaseResultJson__c,
                DatabaseResultType__c = logEntryEvent.DatabaseResultType__c,
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
                LimitsSoslSearchesUsed__c = logEntryEvent.LimitsSoslSearchesUsed__c,
                LimitsSoslSearchesMax__c = logEntryEvent.LimitsSoslSearchesMax__c,
                Log__c = LOG.Id,
                LoggingLevel__c = logEntryEvent.LoggingLevel__c,
                LoggingLevelOrdinal__c = logEntryEvent.LoggingLevelOrdinal__c,
                Message__c = logEntryEvent.Message__c,
                MessageTruncated__c = logEntryEvent.MessageTruncated__c,
                Name = null, // Salesforce will auto-set the record ID as the name when null
                OriginType__c = logEntryEvent.OriginType__c,
                OriginLocation__c = logEntryEvent.OriginLocation__c,
                RecordId__c = logEntryEvent.RecordId__c,
                RecordJson__c = logEntryEvent.RecordJson__c,
                RecordSObjectClassification__c = logEntryEvent.RecordSObjectClassification__c,
                RecordSObjectType__c = logEntryEvent.RecordSObjectType__c,
                RecordSObjectTypeNamespace__c = logEntryEvent.RecordSObjectTypeNamespace__c,
                StackTrace__c = logEntryEvent.StackTrace__c,
                Timestamp__c = timestamp,
                TriggerIsExecuting__c = logEntryEvent.TriggerIsExecuting__c,
                TriggerOperationType__c = logEntryEvent.TriggerOperationType__c,
                TriggerSObjectType__c = logEntryEvent.TriggerSObjectType__c
            );

            this.logEntries.add(logEntry);

            if (logEntryEvent.Topics__c != null) {
                this.topicNames.addAll(logEntryEvent.Topics__c.split(','));
                this.logEntryToTopics.put(logEntry, LogEntryEvent.Topics__c.split(','));
            }
        }

        insert this.logEntries;
    }

    private void insertTopics() {
        if (this.topicNames.isEmpty()) {
            return;
        }

        // Query for existing topics
        Map<String, Topic> topicNameToTopics = new Map<String, Topic>();
        for (Topic topic : [SELECT Id, Name FROM Topic WHERE Name IN :this.topicNames]) {
            topicNameToTopics.put(topic.Name, topic);
        }
        // Create any new topics
        List<Topic> topicsToCreate = new List<Topic>();
        for (String topicName : this.topicNames) {
            if (topicNameToTopics.get(topicName) != null) {
                continue;
            }

            topicsToCreate.add(new Topic(Name = topicName));
        }
        if (!topicsToCreate.isEmpty()) {
            insert topicsToCreate;
            for (Topic topic : topicsToCreate) {
                topicNameToTopics.put(topic.Name, topic);
            }
        }

        // Assign the topics to the records
        Set<TopicAssignment> topicAssignments = new Set<TopicAssignment>();
        for (LogEntry__c logEntry : logEntryToTopics.keySet()) {
            for (String topicName : logEntryToTopics.get(logEntry)) {
                // Add log entry-specific topics
                topicAssignments.add(new TopicAssignment(EntityId = logEntry.Id, TopicId = topicNameToTopics.get(topicName).Id));

                // Add all topics to the parent log when enabled
                topicAssignments.add(new TopicAssignment(EntityId = LOG.Id, TopicId = topicNameToTopics.get(topicName).Id));
            }
        }
        insert new List<TopicAssignment>(topicAssignments);
    }

    // Private static methods
    private static List<Log__c> getRecentLogsWithDetails() {
        Datetime eightHoursAgo = System.now().addMinutes(-8 * 60);

        return [
            SELECT Id, ApiReleaseNumber__c, ApiReleaseVersion__c
            FROM Log__c
            WHERE CreatedDate >= :eightHoursAgo AND DAY_ONLY(CreatedDate) = :System.today() AND ApiReleaseNumber__c != NULL
            LIMIT 1
        ];
    }

    private static Integer getCountOfOpenJobs() {
        return [
            SELECT COUNT()
            FROM AsyncApexJob
            WHERE ApexClass.Name = :QueueableStatusApiCaller.class.getName() AND Status IN ('Holding', 'Queued', 'Preparing', 'Processing')
        ];
    }

    // Private class for calling the Status API and updating `Log__c` records
    // TODO this name is terrible
    private class QueueableStatusApiCaller implements Queueable, Database.AllowsCallouts {
        public void execute(System.QueueableContext queueableContext) {
            System.debug('Running QueueableStatusApiCaller.execute(System.QueueableContext queueableContext)');

            Organization organization = [SELECT InstanceName FROM Organization];
            String statusApiEndpoint = 'https://api.status.salesforce.com/v1/instances/' + organization.InstanceName + '/status';

            HttpRequest request = new HttpRequest();
            request.setEndpoint(statusApiEndpoint);
            request.setMethod('GET');

            HttpResponse response = new Http().send(request);
            StatusApiResponse statusApiResponse = (StatusApiResponse) JSON.deserialize(response.getBody(), StatusApiResponse.class);
            System.debug('statusApiResponse==' + statusApiResponse);

            List<Log__c> logsToUpdate = new List<Log__c>();
            for (Log__c log : [SELECT Id FROM Log__c WHERE DAY_ONLY(CreatedDate) = TODAY AND ApiReleaseNumber__c = NULL]) {
                log.ApiReleaseNumber__c = statusApiResponse.releaseNumber;
                log.ApiReleaseVersion__c = statusApiResponse.releaseVersion;

                logsToUpdate.add(log);
            }
            update logsToUpdate;
        }
    }

    // Private class for handling the response from api.status.salesforce.com
    private class StatusApiResponse {
        public String releaseNumber { get; set; }
        public String releaseVersion { get; set; }
    }
}
