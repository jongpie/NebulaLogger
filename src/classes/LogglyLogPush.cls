public without sharing class LogglyLogPush implements Database.Batchable<Log__c>, Database.AllowsCallouts {

    private static final LoggerIntegration__mdt SETTINGS = [SELECT BaseUrl__c, ApiToken__c FROM LoggerIntegration__mdt WHERE DeveloperName = 'Loggly'];

    public List<Log__c> start(Database.BatchableContext batchableContext) {
        return (List<Log__c>)Database.query(this.getQuery());
    }

    public void execute(Database.BatchableContext batchableContext, List<Log__c> logs) {
        List<String> logEntryStrings = new List<String>();
        for(Log__c log : logs) {
            for(LogEntry__c logEntry : log.LogEntries__r) {
                LogDto convertedLogEntry = convertLogEntry(log, logEntry);
                logEntryStrings.add(Json.serialize(convertedLogEntry));
            }
            log.PushedToLogglyDate__c = System.now();
        }

        HttpRequest request = new HttpRequest();
        request.setEndpoint(SETTINGS.BaseUrl__c + '/bulk/' + SETTINGS.ApiToken__c + '/tag/bulk/');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'text/plain');
        request.setBody(String.join(logEntryStrings, '\n'));
        // TODO figure out how to best use Loggly tags
        //if(!tags.isEmpty()) request.setHeader('X-LOGGLY-TAG', String.join(tags, ','));

        HttpResponse response = new Http().send(request);
        System.debug(response.toString());
        update logs;
    }

    public void finish(Database.BatchableContext batchableContext) {
        // If new logs have generated while the batch has been running, start a new batch
        Integer remainingLogEntries = Database.countQuery(this.getCountQuery());
        if(remainingLogEntries > 0) Database.executeBatch(new LogglyLogPush());
    }

    private String getQuery() {
        return String.format(this.getBaseQuery(), new List<String>{String.join(this.getQueryFields(), ', ')});
    }

    private String getCountQuery() {
        String count = 'count()';
        return String.format(this.getBaseQuery(), new List<String>{count});
    }

    private List<String> getQueryFields() {
        List<String> logQueryFields = new List<String>();
        logQueryFields.add(String.valueOf(Schema.Log__c.Name));
        logQueryFields.add(String.valueOf(Schema.Log__c.LoggedBy__c));
        logQueryFields.add('LoggedBy__r.Name');
        logQueryFields.add(String.valueOf(Schema.Log__c.TransactionId__c));
        logQueryFields.sort();

        // LogEntry__c fields
        List<String> logEntryQueryFields = new List<String>{
            String.valueOf(Schema.LogEntry__c.Id), String.valueOf(Schema.LogEntry__c.ClassName__c),
            String.valueOf(Schema.LogEntry__c.ExceptionStackTrace__c), String.valueOf(Schema.LogEntry__c.ExceptionTypeName__c),
            String.valueOf(Schema.LogEntry__c.Log__c), String.valueOf(Schema.LogEntry__c.Message__c),
            String.valueOf(Schema.LogEntry__c.MethodName__c), String.valueOf(Schema.LogEntry__c.Source__c),
            String.valueOf(Schema.LogEntry__c.Timestamp__c), String.valueOf(Schema.LogEntry__c.TransactionEntryId__c),
            String.valueOf(Schema.LogEntry__c.Type__c)
        };
        logEntryQueryFields.sort();

        String childRelationshipName;
        for(Schema.ChildRelationship childRelationship : Log__c.SObjectType.getDescribe().getChildRelationships()) {
            if(childRelationship.getField() != Schema.LogEntry__c.Log__c) continue;

            childRelationshipName = childRelationship.getRelationshipName();
            break;
        }

        logQueryFields.add('(SELECT ' + String.join(logEntryQueryFields, ', ') + ' FROM ' + childRelationshipName + ')');
        return logQueryFields;
    }

    private String getBaseQuery() {
        id myid = 'a050Y00000RUGUG';
        return 'SELECT {0} FROM ' + Schema.Log__c.SobjectType
            + ' WHERE ' + Schema.Log__c.PushToLoggly__c + ' = true'
            + ' AND ' + Schema.Log__c.PushedToLogglyDate__c + ' = null';
    }

    private static String getFormattedTimestamp(Datetime timestamp) {
        return timestamp.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'Greenwich Mean Time');
    }

    private static LogDto convertLogEntry(Log__c parentLog, LogEntry__c logEntry) {
        UserDto user = new UserDto();
        user.Id        = parentLog.LoggedBy__c;
        user.Name      = parentLog.LoggedBy__r.Name;
        user.ProfileId = UserInfo.getProfileId();

        OrganizationDto organization = new OrganizationDto();
        organization.Id   = UserInfo.getOrganizationId();
        organization.Name = UserInfo.getOrganizationName();

        LogDto log = new LogDto();
        log.ClassName           = logEntry.ClassName__c;
        log.ExceptionStackTrace = logEntry.ExceptionStackTrace__c;
        log.ExceptionType       = logEntry.ExceptionTypeName__c;
        log.Location            = logEntry.Source__c;
        log.LogEntryId          = logEntry.Id;
        log.LogId               = logEntry.Log__c;
        log.Message             = logEntry.Message__c;
        log.MethodName          = logEntry.MethodName__c;
        log.Organization        = organization;
        log.Timestamp           = getFormattedTimestamp(logEntry.Timestamp__c);
        log.TransactionEntryId  = logEntry.TransactionEntryId__c;
        log.TransactionId       = parentLog.TransactionId__c;
        log.Type                = logEntry.Type__c;
        log.User                = user;

        return log;
    }

    private class LogDto {
        public String ClassName;
        public String ExceptionStackTrace;
        public String ExceptionType;
        public String Location;
        public Id LogId;
        public Id LogEntryId;
        public String Message;
        public String MethodName;
        public OrganizationDto Organization;
        public String Timestamp;
        public String TransactionEntryId;
        public String TransactionId;
        public String Type;
        public UserDto User;
    }

    private class OrganizationDto {
        public Id Id;
        public String Name;
    }

    private class ProfileDto {
        public Id Id;
        public String Name;
    }

    private class UserDto {
        public Id Id;
        public String Name;
        public Id ProfileId;
    }

}