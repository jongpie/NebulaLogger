//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

public without sharing class SlackLoggerPlugin implements LoggerSObjectHandlerPlugin, Queueable, Database.AllowsCallouts {
    private List<Log__c> logs;

    public SlackLoggerPlugin() {
    }

    private SlackLoggerPlugin(List<Log__c> unsentLogs) {
        this.logs = unsentLogs;
    }

    public void execute(
        TriggerOperation triggerOperationType,
        List<SObject> triggerNew,
        Map<Id, SObject> triggerNewMap,
        List<SObject> triggerOld,
        Map<Id, SObject> triggerOldMap
    ) {
        switch on triggerOperationType {
            when BEFORE_INSERT, BEFORE_UPDATE {
                this.flagLogsForSlackNotification((List<Log__c>) triggerNew);
            }
            when AFTER_INSERT, AFTER_UPDATE {
                this.sendAsyncSlackNotifications((List<Log__c>) triggerNew);
            }
        }
    }

    public void execute(System.QueueableContext queueableContext) {
        // Requery the logs, in case any field values have changed
        this.requeryLogs();

        if (this.logs.isEmpty() == true) {
            return;
        }

        List<Log__c> sentLogs = new List<Log__c>();
        List<Log__c> unsentLogs = new List<Log__c>();
        for (Log__c log : this.logs) {
            // log = log.clone(true);
            if (Limits.getCallouts() == Limits.getLimitCallouts()) {
                // If there are too many logs to send in the same transaction...
                // ...add them to the unsentLogs list, which will be queued as a separate job
                unsentLogs.add(log);
            } else {
                NotificationDto notification = new NotificationDto();
                notification.text = 'Salesforce Log Alert';
                notification.attachments = new List<LogDto>();
                notification.attachments.add(this.convertLog(log));

                HttpRequest request = new HttpRequest();
                request.setEndpoint('callout:Slack');
                request.setMethod('POST');
                request.setHeader('Content-Type', 'application/json');

                // 'Short' is a reserved word in Apex, but used in Slack's API, so the conversion happens in JSON
                String notificationJson = JSON.serialize(notification).replace('"isShort"', '"short"');
                request.setBody(notificationJson);

                HttpResponse response = new Http().send(request);
                System.debug('response.getStatusCode()==' + response.getStatusCode());
                System.debug('response.getStatus()==' + response.getStatus());

                log.SlackNotificationDate__c = System.now();
                sentLogs.add(log);
            }
        }
        update sentLogs;

        // If any logs couldn't be sent due to governor limits, start a new instance of the job
        if (unsentLogs.isEmpty() == false) {
            System.enqueueJob(new SlackLoggerPlugin(unsentLogs));
        }
    }

    private void flagLogsForSlackNotification(List<Log__c> logs) {
        for (Log__c log : logs) {
            if (log.TotalERRORLogEntries__c > 0 || log.TotalWARNLogEntries__c > 0) {
                log.SendSlackNotification__c = true;
            }
        }
    }

    private void sendAsyncSlackNotifications(List<Log__c> logs) {
        List<Log__c> logsToSend = new List<Log__c>();
        for (Log__c log : logs) {
            if (log.SendSlackNotification__c == true) {
                logsToSend.add(log);
            }
        }

        // Since plugins are called from trigger handlers, and triggers can't make callouts...
        // ...run this class as a queueable (async) job
        if (logsToSend.isEmpty() == false) {
            System.enqueueJob(new SlackLoggerPlugin(logsToSend));
        }
    }

    private void requeryLogs() {
        this.logs = [
            SELECT
                Id,
                Name,
                LoggedBy__c,
                LoggedBy__r.Name,
                TotalLogEntries__c,
                TotalERRORLogEntries__c,
                TotalWARNLogEntries__c,
                TransactionId__c,
                (SELECT Id, Message__c FROM LogEntries__r WHERE LoggingLevelOrdinal__c >= :LoggingLevel.WARN.ordinal() ORDER BY Timestamp__c)
            FROM Log__c
            WHERE Id IN :this.logs AND SendSlackNotification__c = TRUE AND SlackNotificationDate__c = NULL
        ];
    }

    private LogDto convertLog(Log__c log) {
        LogDto notification = new LogDto();
        notification.author_link = Url.getSalesforceBaseUrl().toExternalForm() + '/' + log.LoggedBy__c;
        notification.author_name = log.LoggedBy__r.Name;
        notification.color = this.getNotificationColor(log);
        notification.fields = new List<FieldDto>();
        notification.text = 'Transaction ID: ' + log.TransactionId__c;
        notification.title = log.Name;
        notification.title_link = Url.getSalesforceBaseUrl().toExternalForm() + '/' + log.Id;

        FieldDto orgNameField = new FieldDto();
        orgNameField.isShort = false;
        orgNameField.title = 'Org Name';
        orgNameField.value = UserInfo.getOrganizationName();
        notification.fields.add(orgNameField);

        FieldDto orgIdField = new FieldDto();
        orgIdField.isShort = true;
        orgIdField.title = 'Org ID';
        orgIdField.value = '`' + UserInfo.getOrganizationId() + '`';
        notification.fields.add(orgIdField);

        // FieldDto orgIsProductionField = new FieldDto();
        // orgIsProductionField.isShort = true;
        // orgIsProductionField.title   = 'Production';
        // orgIsProductionField.value   = '`' + !ORG.IsSandbox + '`';
        // notification.fields.add(orgIsProductionField);

        FieldDto totalEntriesField = new FieldDto();
        totalEntriesField.isShort = true;
        totalEntriesField.title = '# of Total Entries';
        totalEntriesField.value = String.valueOf(log.TotalLogEntries__c);
        notification.fields.add(totalEntriesField);

        FieldDto totalERROREntriesField = new FieldDto();
        totalERROREntriesField.isShort = true;
        totalERROREntriesField.title = '# of ERROR Entries';
        totalERROREntriesField.value = String.valueOf(log.TotalERRORLogEntries__c);
        notification.fields.add(totalERROREntriesField);

        FieldDto totalWARNEntriesField = new FieldDto();
        totalWARNEntriesField.isShort = true;
        totalWARNEntriesField.title = '# of WARN Entries';
        totalWARNEntriesField.value = String.valueOf(log.TotalWARNLogEntries__c);
        notification.fields.add(totalWARNEntriesField);

        FieldDto logEntryField = new FieldDto();
        logEntryField.isShort = false;
        logEntryField.title = 'Log Entry Message';
        logEntryField.value = '`' + log.LogEntries__r.get(0).Message__c + '`';
        notification.fields.add(logEntryField);

        List<String> topicNames = new List<String>();
        for (TopicAssignment topicAssignment : log.TopicAssignments) {
            topicNames.add(topicAssignment.Topic.Name);
        }
        topicNames.sort();

        if (topicNames.isEmpty() == false) {
            FieldDto topicsField = new FieldDto();
            topicsField.isShort = false;
            topicsField.title = 'Topics';
            topicsField.value = '`' + String.join(topicNames, '`, `') + '`';
            notification.fields.add(topicsField);
        }

        return notification;
    }

    private String getNotificationColor(Log__c log) {
        String color;

        if (log.TotalERRORLogEntries__c >= 1) {
            color = '#FF7373';
        } else if (log.TotalWARNLogEntries__c >= 1) {
            color = '#FFC873';
        } else {
            color = '#7CD197';
        }

        return color;
    }

    // Private DTO classes that match Slack's API
    private class NotificationDto {
        public List<LogDto> attachments;
        public String text;
    }

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
