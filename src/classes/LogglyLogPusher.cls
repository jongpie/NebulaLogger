/*************************************************************************************************
* This file is part of the Nebula Logger project, released under the MIT License.                *
* See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    *
*************************************************************************************************/
public without sharing class LogglyLogPusher implements Database.AllowsCallouts, Database.Batchable<Log__c> {

    private static final Organization ORG                = [SELECT Id, IsSandbox FROM Organization LIMIT 1];
    private static final LoggerIntegration__mdt SETTINGS = [SELECT ApiToken__c, BaseUrl__c, UrlParameters__c FROM LoggerIntegration__mdt WHERE DeveloperName = 'Loggly'];

    public List<Log__c> start(Database.BatchableContext batchableContext) {
        return [
            SELECT Name, LoggedBy__r.Name, LoggedBy__c, TransactionId__c
            FROM Log__c
            WHERE PushToLoggly__c = true
            AND PushedToLogglyDate__c = null
            AND TotalLogEntries__c > 0
        ];
    }

    public void execute(Database.BatchableContext batchableContext, List<Log__c> logs) {
        List<String> logEntryStrings = new List<String>();
        Map<Id, List<LogEntry__c>> logEntriesMap = this.getLogEntriesMap(logs);
        for(Log__c log : logs) {
            List<LogEntry__c> logEntries = logEntriesMap.get(log.Id);
            for(LogEntry__c logEntry : logEntries) {
                LogDto convertedLogEntry = this.convertLogEntry(log, logEntry);
                logEntryStrings.add(Json.serialize(convertedLogEntry));
            }
            log.PushedToLogglyDate__c = System.now();
        }

        String urlParameters = SETTINGS.UrlParameters__c == null ? '' : '?' + SETTINGS.UrlParameters__c.replace('\n', '&');
        HttpRequest request = new HttpRequest();
        request.setEndpoint(SETTINGS.BaseUrl__c + '/bulk/' + SETTINGS.ApiToken__c + '/tag/salesforce/' + urlParameters);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'text/plain');
        request.setBody(String.join(logEntryStrings, '\n'));

        HttpResponse response = new Http().send(request);

        if(response.getStatusCode() >= 400) throw new LogglyApiException(response.getBody());

        update logs;
    }

    public void finish(Database.BatchableContext batchableContext) {}

    private String getFormattedTimestamp(Datetime timestamp) {
        return timestamp.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'Greenwich Mean Time');
    }

    private Map<Id, List<LogEntry__c>> getLogEntriesMap(List<Log__c> logs) {
        Map<Id, List<LogEntry__c>> logEntriesMap = new Map<Id, List<LogEntry__c>>();
        // TODO cleanup formatting of code
        for(LogEntry__c logEntry : [
            SELECT Id, ExceptionStackTrace__c, ExceptionType__c, Log__c, Message__c, OriginLocation__c, OriginType__c,
                Timestamp__c, TransactionEntryId__c, Type__c,
                (SELECT Topic.Name FROM TopicAssignments)
            FROM LogEntry__c
            WHERE Log__c IN :logs
        ]) {
            if(!logEntriesMap.containsKey(logEntry.Log__c)) logEntriesMap.put(logEntry.Log__c, new List<LogEntry__c>());

            List<LogEntry__c> logEntries = logEntriesMap.get(logEntry.Log__c);
            logEntries.add(logEntry);
            logEntriesMap.put(logEntry.Log__c, logEntries);
        }

        return logEntriesMap;
    }

    private LogDto convertLogEntry(Log__c parentLog, LogEntry__c logEntry) {
        UserDto user = new UserDto();
        user.id        = parentLog.LoggedBy__c;
        user.name      = parentLog.LoggedBy__r.Name;
        user.profileId = UserInfo.getProfileId();

        OrganizationDto organization = new OrganizationDto();
        organization.id   = UserInfo.getOrganizationId();
        organization.name = UserInfo.getOrganizationName();

        List<String> topicNames = new List<String>();
        for(TopicAssignment topicAssignment : logEntry.TopicAssignments) {
            topicNames.add(topicAssignment.Topic.Name);
        }

        LogDto log = new LogDto();
        log.exceptionStackTrace = logEntry.ExceptionStackTrace__c;
        log.exceptionType       = logEntry.ExceptionType__c;
        log.originIsProduction  = !ORG.IsSandbox;
        log.originLocation      = logEntry.OriginLocation__c;
        log.originType          = logEntry.OriginType__c;
        log.logEntryId          = logEntry.Id;
        log.logId               = logEntry.Log__c;
        log.logType             = logEntry.Type__c;
        log.logUrl              = Url.getSalesforceBaseUrl().toExternalForm() + '/' + logEntry.Log__c;
        log.message             = logEntry.Message__c;
        log.organization        = organization;
        log.sourceSystem        = 'Salesforce';
        log.sourceUrl           = Url.getSalesforceBaseUrl().toExternalForm();
        log.timestamp           = this.getFormattedTimestamp(logEntry.Timestamp__c);
        log.topics              = topicNames;
        log.transactionEntryId  = logEntry.TransactionEntryId__c;
        log.transactionId       = parentLog.TransactionId__c;
        log.user                = user;

        return log;
    }

    private class LogglyApiException extends Exception {}

    private class LogDto {
        public String className;
        public String exceptionStackTrace;
        public String exceptionType;
        public String location;
        public Id logId;
        public Id logEntryId;
        public String logType;
        public String logUrl;
        public String message;
        public Boolean originIsProduction;
        public String originLocation;
        public String originType;
        public OrganizationDto organization;
        public String sourceSystem;
        public String sourceUrl;
        public String timestamp;
        public List<String> topics;
        public String transactionEntryId;
        public String transactionId;
        public UserDto user;
    }

    private class OrganizationDto {
        public Id id;
        public String name;
    }

    private class ProfileDto {
        public Id id;
        public String name;
    }

    private class UserDto {
        public Id id;
        public String name;
        public Id profileId;
    }

}