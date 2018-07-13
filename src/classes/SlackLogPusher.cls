/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class SlackLogPusher implements Database.AllowsCallouts, Database.Batchable<Log__c>  {

    private static final Organization ORG                = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
    private static final LoggerIntegration__mdt SETTINGS = [SELECT ApiToken__c, BaseUrl__c FROM LoggerIntegration__mdt WHERE DeveloperName = 'Slack'];

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

            HttpRequest request = new HttpRequest();
            request.setEndpoint(SETTINGS.BaseUrl__c + SETTINGS.ApiToken__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            String jsonString = Json.serialize(notification);
            // 'Short' is a reserved word in Apex, but used in Slack's API, so the conversion happens in JSON
            jsonString = jsonString.replace('"isShort"', '"short"');
            request.setBody(jsonString);

            HttpResponse response = new Http().send(request);

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

        FieldDto orgInfoField = new FieldDto();
        orgInfoField.isShort = false;
        orgInfoField.title   = 'Salesforce Org';
        orgInfoField.value   = 'Name: ' + UserInfo.getOrganizationName()
            + '\nID: `' + UserInfo.getOrganizationId() + '`'
            + '\nProduction: ' + '`' + !ORG.IsSandbox + '`';
        notification.fields.add(orgInfoField);

        FieldDto totalExceptionsField = new FieldDto();
        totalExceptionsField.isShort = true;
        totalExceptionsField.title   = '# of Exception Entries';
        totalExceptionsField.value   = String.valueOf(log.TotalExceptionLogEntries__c);
        notification.fields.add(totalExceptionsField);

        FieldDto totalDebugsField = new FieldDto();
        totalDebugsField.isShort = true;
        totalDebugsField.title   = '# of Debug Entries';
        totalDebugsField.value   = String.valueOf(log.TotalDebugLogEntries__c);
        notification.fields.add(totalDebugsField);

        List<String> topicNames = new List<String>();
        for(TopicAssignment topicAssignment : log.TopicAssignments) {
            topicNames.add(topicAssignment.Topic.Name);
        }
        topicNames.sort();

        if(topicNames.isEmpty()) return notification;

        FieldDto topicsField = new FieldDto();
        topicsField.isShort = false;
        topicsField.title   = 'Topics';
        topicsField.value   = String.join(topicNames, ', ');
        notification.fields.add(topicsField);

        return notification;
    }

    private class NotificationDto {
        public String text;
        public List<LogDto> attachments;
    }

    private class LogDto {
        public String fallback;
        public String color;
        public String pretext;
        public String author_name;
        public String author_link;
        public String author_icon;
        public String title;
        public String title_link;
        public String text;
        public List<ActionDto> actions;
        public List<FieldDto> fields;
    }

    private class ActionDto {
        public String type;
        public String text;
        public String url;
    }

    private class FieldDto {
        public String title;
        public String value;
        public Boolean isShort;
    }
/*
{
    "attachments": [
        {
            "fallback": "Required plain-text summary of the attachment.",
            "color": "#2eb886",
            "pretext": "Optional text that appears above the attachment block",
            "author_name": "Bobby Tables",
            "author_link": "http://flickr.com/bobby/",
            "author_icon": "http://flickr.com/icons/bobby.jpg",
            "title": "Slack API Documentation",
            "title_link": "https://api.slack.com/",
            "text": "Optional text that appears within the attachment",
            "fields": [
                {
                    "title": "Priority",
                    "value": "High",
                    "short": false
                }
            ],
            "image_url": "http://my-website.com/path/to/image.jpg",
            "thumb_url": "http://example.com/path/to/thumb.png",
            "footer": "Slack API",
            "footer_icon": "https://platform.slack-edge.com/img/default_application_icon.png",
            "ts": 123456789
        }
    ]
}
*/


}