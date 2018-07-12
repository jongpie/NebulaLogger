/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class SlackLogPusher implements Database.Batchable<Log__c>, Database.AllowsCallouts {

    private static final Organization ORG = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
    private static final LoggerIntegration__mdt SETTINGS = [SELECT BaseUrl__c, ApiToken__c FROM LoggerIntegration__mdt WHERE DeveloperName = 'Slack'];

    public List<Log__c> start(Database.BatchableContext batchableContext) {
        return (List<Log__c>)Database.query(this.getQuery() + ' ORDER BY CreatedDate DESC LIMIT 1');
    }

    public void execute(Database.BatchableContext batchableContext, List<Log__c> logs) {
        for(Log__c log : logs) {
            NotificationDto notification = new NotificationDto();
            notification.text = 'New Salesforce Log Created';
            notification.attachments = new List<LogDto>();
            notification.attachments.add(convertLog(log));

            HttpRequest request = new HttpRequest();
            request.setEndpoint(SETTINGS.BaseUrl__c + SETTINGS.ApiToken__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'application/json');
            String jsonString = Json.serialize(notification);
            jsonString = jsonString.replace('"isShort"', '"short"');
            request.setBody(jsonString);
            System.debug('ze json=' + Json.serialize(notification).replace('"isShort"', '"short"'));

            HttpResponse response = new Http().send(request);
            System.debug(response.toString());

            log.PushedToSlackDate__c = System.now();
        }

        update logs;
    }

    public void finish(Database.BatchableContext batchableContext) {
        // If new logs have generated while the batch has been running, start a new batch
        Integer countOfRemainingLogEntries = Database.countQuery(this.getCountQuery());
        if(countOfRemainingLogEntries > 0) Database.executeBatch(new SlackLogPusher());
    }

    private String getQuery() {
        return String.format(this.getBaseQuery(), new List<String>{String.join(this.getQueryFields(), ', ')});
    }

    private String getCountQuery() {
        String count = 'count()';
        return String.format(this.getBaseQuery(), new List<String>{count});
    }

    private String getBaseQuery() {
        return 'SELECT {0} FROM ' + Schema.Log__c.SobjectType
            + ' WHERE ' + Schema.Log__c.PushToSlack__c + ' = true'
            + ' AND ' + Schema.Log__c.PushedToSlackDate__c + ' = null';
    }

    private List<String> getQueryFields() {
        List<String> queryFields = new List<String>();
        queryFields.add(String.valueOf(Schema.Log__c.LoggedBy__c));
        queryFields.add('LoggedBy__r.Name');
        queryFields.add(String.valueOf(Schema.Log__c.Name));
        /*queryFields.add(String.valueOf(Schema.Log__c.OwnerId));
        queryFields.add('Owner.Name');
        queryFields.add('Owner.Type');*/
        queryFields.add(String.valueOf(Schema.Log__c.TotalDebugLogEntries__c));
        queryFields.add(String.valueOf(Schema.Log__c.TotalExceptionLogEntries__c));
        queryFields.add(String.valueOf(Schema.Log__c.TransactionId__c));

        queryFields.sort();
        return queryFields;
    }

    private static LogDto convertLog(Log__c log) {
        LogDto notification = new LogDto();
        notification.author_link = Url.getSalesforceBaseUrl().toExternalForm() + '/' + log.LoggedBy__c;
        notification.author_name = log.LoggedBy__r.Name;// + ' (Type: ' + log.Owner.Type + ')';
        notification.color       = log.TotalExceptionLogEntries__c >= 1 ? '#FF7373' : '#7CD197';
        //notification.text        = logEntry.Message__c;
        notification.text        = 'Transaction ID: ' + log.TransactionId__c;
        notification.title       = log.Name;
        notification.title_link  = Url.getSalesforceBaseUrl().toExternalForm() + '/' + log.Id;

        notification.fields = new List<FieldDto>();

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

        //FieldDto userInfoField = new FieldDto();
        //userInfoField.isShort = true;
        //userInfoField.title   = 'Logged By';
        //userInfoField.value   = 'Name: ' + UserInfo.getName()
             //+ '\nID: `' + UserInfo.getUserId() + '`'
             //+ '\nUsername: ' + UserInfo.getUserName();
        //notification.fields.add(userInfoField);

        //notification.actions = new List<ActionDto>();
        //ActionDto logLinkAction = new ActionDto();
        //logLinkAction.type = 'button';
        //logLinkAction.text = 'View ' + log.Name;
        //logLinkAction.url  = Url.getSalesforceBaseUrl().toExternalForm() + '/' + log.Id;
        //notification.actions.add(logLinkAction);

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