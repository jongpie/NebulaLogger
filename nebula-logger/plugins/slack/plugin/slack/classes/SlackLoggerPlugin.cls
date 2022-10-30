//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Plugins
 * @description Optional plugin that integrates with Slack to send alerts for important logs
 */
@SuppressWarnings('PMD.ExcessivePublicCount')
public without sharing class SlackLoggerPlugin implements LoggerPlugin.Triggerable, Queueable, Database.AllowsCallouts {
    @TestVisible
    private static final String ENDPOINT = LoggerParameter.getString('SlackEndpoint', null);
    @TestVisible
    private static final LoggingLevel NOTIFICATION_LOGGING_LEVEL = Logger.getLoggingLevel(LoggerParameter.getString('SlackNotificationLoggingLevel', null));

    private List<Log__c> logs;

    /**
     * @description Default constructor
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public SlackLoggerPlugin() {
    }

    private SlackLoggerPlugin(List<Log__c> unsentLogs) {
        this();
        this.logs = unsentLogs;
    }

    /**
     * @description Handles the integration with Slack. This method is automatically called by Nebula Logger's plugin framework.
     * @param  configuration The instance of `LoggerPlugin__mdt` configured for this specific plugin
     * @param  input The instance of `LoggerTriggerableContext`, provided by the logging system
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public void execute(LoggerPlugin__mdt configuration, LoggerTriggerableContext input) {
        if (input.sobjectType != Schema.Log__c.SObjectType || String.isBlank(ENDPOINT) == true) {
            return;
        }

        this.logs = (List<Log__c>) input.triggerNew;

        switch on input.triggerOperationType {
            when BEFORE_INSERT, BEFORE_UPDATE {
                this.flagLogsForSlackNotification();
            }
            when AFTER_INSERT, AFTER_UPDATE {
                this.sendAsyncSlackNotifications();
            }
        }
    }

    /**
     * @description Handles the queuable execute logic. Required by the Queueable interface.
     * @param queueableContext Context of the current queuable instance.
     */
    public void execute(System.QueueableContext queueableContext) {
        // Since this runs in an async context, requery the logs just in case any field values have changed
        this.requeryLogs();

        if (this.logs.isEmpty() == true) {
            return;
        }

        List<Log__c> sentLogs = new List<Log__c>();
        List<Log__c> unsentLogs = new List<Log__c>();
        for (Log__c log : this.logs) {
            if (Limits.getCallouts() == Limits.getLimitCallouts()) {
                // If there are too many logs to send in the same transaction
                // add them to the unsentLogs list, which will be queued as a separate job
                unsentLogs.add(log);
            } else {
                HttpRequest request = this.createSlackHttpRequest();

                NotificationDto notification = new NotificationDto();
                notification.text = 'Salesforce Log Alert';
                notification.attachments = new List<LogDto>{ this.convertLog(log) };

                // 'Short' is a reserved word in Apex, but used in Slack's API, so the conversion happens in JSON
                String notificationJson = JSON.serialize(notification).replace('"isShort"', '"short"');
                request.setBody(notificationJson);
                if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == true) {
                    Logger.finest('Sending log entries to Slack endpoint').setHttpRequestDetails(request);
                }

                HttpResponse response = new Http().send(request);
                if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == true) {
                    Logger.finest('Sent log entries to Slack endpoint').setHttpResponseDetails(response);
                }

                log.SlackNotificationDate__c = System.now();
                sentLogs.add(log);
            }
        }
        Logger.saveLog();
        update sentLogs;

        // If any logs couldn't be sent due to governor limits, start a new instance of the job
        if (unsentLogs.isEmpty() == false) {
            System.enqueueJob(new SlackLoggerPlugin(unsentLogs));
        }
    }

    private void flagLogsForSlackNotification() {
        if (NOTIFICATION_LOGGING_LEVEL == null) {
            return;
        }

        for (Log__c log : this.logs) {
            if (log.MaxLogEntryLoggingLevelOrdinal__c >= NOTIFICATION_LOGGING_LEVEL.ordinal()) {
                log.SendSlackNotification__c = true;
            }
        }
    }

    private void sendAsyncSlackNotifications() {
        List<Log__c> logsToSend = new List<Log__c>();
        for (Log__c log : this.logs) {
            if (log.SendSlackNotification__c == true) {
                logsToSend.add(log);
            }
        }

        // Since plugins are called from trigger handlers, and triggers can't make callouts
        // run this class as a queueable (async) job
        if (logsToSend.isEmpty() == false) {
            System.enqueueJob(new SlackLoggerPlugin(logsToSend));
        }
    }

    private void requeryLogs() {
        // TODO: switch to dynamically querying based on a new `Log__c` field set parameter
        this.logs = [
            SELECT
                Id,
                Name,
                ApiVersion__c,
                LoggedBy__c,
                LoggedBy__r.Username,
                OwnerId,
                TYPEOF Owner
                    WHEN User THEN Username
                    ELSE Name
                END,
                MaxLogEntryLoggingLevelOrdinal__c,
                OrganizationId__c,
                OrganizationEnvironmentType__c,
                OrganizationInstanceName__c,
                OrganizationName__c,
                Priority__c,
                StartTime__c,
                TimeZoneId__c,
                TotalLogEntries__c,
                TotalERRORLogEntries__c,
                TotalWARNLogEntries__c,
                TransactionId__c,
                (
                    SELECT Id, LoggingLevel__c, Message__c, ExceptionStackTrace__c, StackTrace__c
                    FROM LogEntries__r
                    WHERE LoggingLevelOrdinal__c >= :NOTIFICATION_LOGGING_LEVEL.ordinal()
                    ORDER BY Timestamp__c DESC
                    LIMIT 1
                )
            FROM Log__c
            WHERE
                Id IN :this.logs
                AND MaxLogEntryLoggingLevelOrdinal__c >= :NOTIFICATION_LOGGING_LEVEL.ordinal()
                AND SendSlackNotification__c = TRUE
                AND SlackNotificationDate__c = NULL
        ];
    }

    private HttpRequest createSlackHttpRequest() {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(ENDPOINT);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');

        if (LoggerParameter.ENABLE_SYSTEM_MESSAGES == true) {
            Logger.finest('Created Slack HTTP Request').setHttpRequestDetails(request);
        }

        return request;
    }

    @SuppressWarnings('PMD.NcssMethodCount')
    private LogDto convertLog(Log__c log) {
        LogEntry__c lastLogEntry = log.LogEntries__r.get(0);
        String messageText = 'Last Log Entry Message' + '\n```' + lastLogEntry.LoggingLevel__c + ': ' + lastLogEntry.Message__c + '```';

        LogDto notification = new LogDto();
        notification.author_link = Url.getSalesforceBaseUrl().toExternalForm() + '/' + log.LoggedBy__c;
        notification.author_name = log.LoggedBy__r.Username;
        notification.color = this.getNotificationColor(log);
        notification.fields = new List<FieldDto>();
        notification.text = messageText; //Schema.Log__c.TotalLogEntries__c.getDescribe().getLabel() + ': `' + String.valueOf(log.TotalLogEntries__c) + '`';
        notification.title = log.Name;
        notification.title_link = Url.getSalesforceBaseUrl().toExternalForm() + '/' + log.Id;

        if (String.isNotBlank(lastLogEntry.ExceptionStackTrace__c) == true) {
            FieldDto exceptionStackTraceField = new FieldDto();
            exceptionStackTraceField.isShort = false;
            exceptionStackTraceField.title = Schema.LogEntry__c.ExceptionStackTrace__c.getDescribe().getLabel();
            exceptionStackTraceField.value = '```\n' + lastLogEntry.ExceptionStackTrace__c + '\n```';
            notification.fields.add(exceptionStackTraceField);
        }

        FieldDto stackTraceField = new FieldDto();
        stackTraceField.isShort = false;
        stackTraceField.title = Schema.LogEntry__c.StackTrace__c.getDescribe().getLabel();
        stackTraceField.value = '```\n' + lastLogEntry.StackTrace__c + '\n```';
        notification.fields.add(stackTraceField);

        // TODO: switch to dynamically creating Slack DTO fields based on a new `Log__c` field set parameter
        FieldDto startTimeField = new FieldDto();
        startTimeField.isShort = true;
        startTimeField.title = Schema.Log__c.StartTime__c.getDescribe().getLabel();
        startTimeField.value = '`' + log.StartTime__c.format() + ' ' + log.TimeZoneId__c + '`';
        notification.fields.add(startTimeField);

        FieldDto transactionIdField = new FieldDto();
        transactionIdField.isShort = true;
        transactionIdField.title = Schema.Log__c.TransactionId__c.getDescribe().getLabel();
        transactionIdField.value = '`' + log.TransactionId__c + '`';
        notification.fields.add(transactionIdField);

        FieldDto totalERROREntriesField = new FieldDto();
        totalERROREntriesField.isShort = true;
        totalERROREntriesField.title = Schema.Log__c.TotalERRORLogEntries__c.getDescribe().getLabel();
        totalERROREntriesField.value = '`' + String.valueOf(log.TotalERRORLogEntries__c) + '`';
        notification.fields.add(totalERROREntriesField);

        FieldDto totalWARNEntriesField = new FieldDto();
        totalWARNEntriesField.isShort = true;
        totalWARNEntriesField.title = Schema.Log__c.TotalWARNLogEntries__c.getDescribe().getLabel();
        totalWARNEntriesField.value = '`' + String.valueOf(log.TotalWARNLogEntries__c) + '`';
        notification.fields.add(totalWARNEntriesField);

        // TODO Add Scenario__c field

        String logOwnerType = log.OwnerId.getSObjectType().getDescribe().getName();
        FieldDto logOwnerNameField = new FieldDto();
        logOwnerNameField.isShort = true;
        logOwnerNameField.title = 'Log Owner';
        logOwnerNameField.value = logOwnerType == 'Group' ? '`Queue: ' + log.Owner.Name + '`' : '`User: ' + log.Owner.Username + '`';
        notification.fields.add(logOwnerNameField);

        FieldDto priorityField = new FieldDto();
        priorityField.isShort = true;
        priorityField.title = Schema.Log__c.Priority__c.getDescribe().getLabel();
        priorityField.value = '`' + log.Priority__c + '`';
        notification.fields.add(priorityField);

        FieldDto orgIdField = new FieldDto();
        orgIdField.isShort = true;
        orgIdField.title = 'Org ID';
        orgIdField.value = '`' + log.OrganizationId__c + '`';
        notification.fields.add(orgIdField);

        FieldDto orgNameField = new FieldDto();
        orgNameField.isShort = true;
        orgNameField.title = 'Org Name';
        orgNameField.value = '`' + log.OrganizationName__c + '`';
        notification.fields.add(orgNameField);

        FieldDto orgTypeField = new FieldDto();
        orgTypeField.isShort = true;
        orgTypeField.title = 'Org Type & Instance';
        orgTypeField.value = '`' + log.OrganizationEnvironmentType__c + ' - ' + log.OrganizationInstanceName__c + '`';
        notification.fields.add(orgTypeField);

        FieldDto orgApiVersion = new FieldDto();
        orgApiVersion.isShort = true;
        orgApiVersion.title = Schema.Log__c.ApiVersion__c.getDescribe().getLabel();
        orgApiVersion.value = '`' + log.ApiVersion__c + '`';
        notification.fields.add(orgApiVersion);

        // TODO Possible include to LogEntryTag__c (tag names)

        return notification;
    }

    private String getNotificationColor(Log__c log) {
        String color;

        if (log.TotalERRORLogEntries__c >= 1) {
            color = '#FF7373'; // Red
        } else if (log.TotalWARNLogEntries__c >= 1) {
            color = '#FFC873'; // Orange
        } else {
            color = '#7CD197'; // Green
        }

        return color;
    }

    // Private DTO classes that match Slack's API
    private class NotificationDto {
        public List<LogDto> attachments;
        public String text;
    }

    @SuppressWarnings('PMD.FieldNamingConventions, PMD.VariableNamingConventions')
    private class LogDto {
        public List<ActionDto> actions;
        public String author_name;
        public String author_link;
        public String author_icon;
        public String color;
        public String fallback;
        public List<FieldDto> fields;
        public String pretext;
        public String text;
        public String title;
        public String title_link;
    }

    private class ActionDto {
        public String text;
        public String type;
        public String url;
    }

    private class FieldDto {
        public Boolean isShort;
        public String title;
        public String value;
    }
}
