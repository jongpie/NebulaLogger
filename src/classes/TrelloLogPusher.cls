/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class TrelloLogPusher implements Database.AllowsCallouts, Database.Batchable<Log__c> {

    private static final LoggerIntegration__mdt SETTINGS = [SELECT ApiKey__c, ApiToken__c, BaseUrl__c, UrlParameters__c FROM LoggerIntegration__mdt WHERE DeveloperName = 'Trello'];

    public List<Log__c> start(Database.BatchableContext batchableContext) {
        return [
            SELECT
                LoggedBy__r.Name, LoggedBy__c, Name, TransactionId__c,
                // Get the most recent exception entry - this will be used to created the Trello card
                (
                    SELECT ExceptionStackTrace__c, ExceptionType__c, Message__c, Timestamp__c
                    FROM LogEntries__r
                    WHERE Type__c = 'Exception'
                    ORDER BY Timestamp__c
                    DESC LIMIT 1
                ),
                (SELECT Topic.Name FROM TopicAssignments)
            FROM Log__c
            WHERE PushToTrello__c = true
            AND PushedToTrelloDate__c = null
            AND TotalExceptionLogEntries__c > 0
        ];
    }

    public void execute(Database.BatchableContext batchableContext, List<Log__c> logs) {
        for(Log__c log : logs) {
            LogEntry__c lastException = log.LogEntries__r[0];

            String cardName = log.Name + ' logged by ' + log.LoggedBy__r.Name;

            List<String> topicNames = new List<String>();
            for(TopicAssignment topicAssignment : log.TopicAssignments) {
                topicNames.add('#' + topicAssignment.Topic.Name);
            }
            if(!topicNames.isEmpty()) cardName +=  '\n\n' + String.join(topicNames, ' ');

            String cardDescription =
                '**Transaction ID:** ' + log.TransactionId__c
                + '\n\n**Timestamp:** ' + this.getFormattedTimestamp(lastException.Timestamp__c)
                + '\n\n**Exception Type:** ' + lastException.ExceptionType__c
                + '\n\n**Message:** ' + lastException.Message__c
                + '\n\n**Stack Trace:** ' + lastException.ExceptionStackTrace__c;

            String urlParameters = SETTINGS.UrlParameters__c == null ? '' : '&' + SETTINGS.UrlParameters__c.replace('\n', '&').replace('\r', '').replace(' ', '');
            String newTrelloCardEndpoint = SETTINGS.BaseUrl__c + '/1/cards'
                + '?name=' + EncodingUtil.urlEncode(cardName, 'UTF-8').replace('+', '%20')
                + '&desc=' + EncodingUtil.urlEncode(cardDescription, 'UTF-8').replace('+', '%20')
                + '&urlSource=' + EncodingUtil.urlEncode(Url.getSalesforceBaseUrl().toExternalForm() + '/' + log.Id, 'UTF-8')
                + '&key=' + SETTINGS.ApiKey__c
                + '&token=' + SETTINGS.ApiToken__c
                + urlParameters;

            HttpRequest request = new HttpRequest();
            request.setEndpoint(newTrelloCardEndpoint);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'text/plain');
            HttpResponse response = new Http().send(request);

            if(response.getStatusCode() >= 400) throw new TrelloApiException(response.getBody());

            log.PushedToTrelloDate__c = System.now();
        }
        update logs;
    }

    public void finish(Database.BatchableContext batchableContext) {}

    private String getFormattedTimestamp(Datetime timestamp) {
        return timestamp.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'Greenwich Mean Time');
    }

    private class TrelloApiException extends Exception {}

}