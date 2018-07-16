/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class SlackLogPusher implements Database.AllowsCallouts, Database.Batchable<Log__c>  {

    private static final Organization ORG                = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
    private static final LoggerIntegration__mdt SETTINGS = [SELECT ApiToken__c, BaseUrl__c, UrlParameters__c FROM LoggerIntegration__mdt WHERE DeveloperName = 'Slack'];

    public List<Log__c> start(Database.BatchableContext batchableContext) {
        return [
            SELECT
                LoggedBy__c, LoggedBy__r.Name, Name,
                TotalDebugLogEntries__c, TotalExceptionLogEntries__c, TransactionId__c,
                (SELECT Topic.Name FROM TopicAssignments)
            FROM Log__c
            WHERE PushToSlack__c = true
            AND PushedToSlackDate__c = null
            AND TotalLogEntries__c > 0
        ];
    }

    public void execute(Database.BatchableContext batchableContext, List<Log__c> logs) {
        for(Log__c log : logs) {
            NotificationDto notification = new NotificationDto();
            notification.text = 'New Salesforce Log Created';
            notification.attachments = new List<LogDto>();
            notification.attachments.add(this.convertLog(log));

            String urlParameters = SETTINGS.UrlParameters__c == null ? '' : '?' + SETTINGS.UrlParameters__c.replace('\n', '&');
            HttpRequest request = new HttpRequest();
            request.setEndpoint(SETTINGS.BaseUrl__c + '/services/' + SETTINGS.ApiToken__c + urlParameters);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            String jsonString = Json.serialize(notification);
            // 'Short' is a reserved word in Apex, but used in Slack's API, so the conversion happens in JSON
            jsonString = jsonString.replace('"isShort"', '"short"');
            request.setBody(jsonString);

            HttpResponse response = new Http().send(request);

            if(response.getStatusCode() >= 400) throw new SlackApiException(response.getBody());

            log.PushedToSlackDate__c = System.now();
        }

        update logs;
    }

    public void finish(Database.BatchableContext batchableContext) {}

    private LogDto convertLog(Log__c log) {
        LogDto notification = new LogDto();
        notification.author_link = Url.getSalesforceBaseUrl().toExternalForm() + '/' + log.LoggedBy__c;
        notification.author_name = log.LoggedBy__r.Name;
        notification.color       = log.TotalExceptionLogEntries__c >= 1 ? '#FF7373' : '#7CD197'; // Red if there are exceptions, otherwise green
        notification.fields      = new List<FieldDto>();
        notification.text        = 'Transaction ID: ' + log.TransactionId__c;
        notification.title       = log.Name;
        notification.title_link  = Url.getSalesforceBaseUrl().toExternalForm() + '/' + log.Id;

        FieldDto orgNameField = new FieldDto();
        orgNameField.isShort = false;
        orgNameField.title   = 'Org Name';
        orgNameField.value   = UserInfo.getOrganizationName();
        notification.fields.add(orgNameField);

        FieldDto orgIdField = new FieldDto();
        orgIdField.isShort = true;
        orgIdField.title   = 'Org ID';
        orgIdField.value   = '`' + UserInfo.getOrganizationId() + '`';
        notification.fields.add(orgIdField);

        FieldDto orgIsProductionField = new FieldDto();
        orgIsProductionField.isShort = true;
        orgIsProductionField.title   = 'Production';
        orgIsProductionField.value   = '`' + !ORG.IsSandbox + '`';
        notification.fields.add(orgIsProductionField);

        FieldDto totalDebugEntriesField = new FieldDto();
        totalDebugEntriesField.isShort = true;
        totalDebugEntriesField.title   = '# of Debug Entries';
        totalDebugEntriesField.value   = String.valueOf(log.TotalDebugLogEntries__c);
        notification.fields.add(totalDebugEntriesField);

        FieldDto totalExceptionEntriesField = new FieldDto();
        totalExceptionEntriesField.isShort = true;
        totalExceptionEntriesField.title   = '# of Exception Entries';
        totalExceptionEntriesField.value   = String.valueOf(log.TotalExceptionLogEntries__c);
        notification.fields.add(totalExceptionEntriesField);

        List<String> topicNames = new List<String>();
        for(TopicAssignment topicAssignment : log.TopicAssignments) {
            topicNames.add(topicAssignment.Topic.Name);
        }

        if(topicNames.isEmpty()) return notification;

        FieldDto topicsField = new FieldDto();
        topicsField.isShort = false;
        topicsField.title   = 'Topics';
        topicsField.value   = String.join(topicNames, ', ');
        notification.fields.add(topicsField);

        return notification;
    }

    private class SlackApiException extends Exception {}

    private class NotificationDto {
        public List<LogDto> attachments;
        public String text;
    }

    private class LogDto {
        public List<ActionDto> actions;
        public String author_name;
        public String author_icon;
        public String author_link;
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