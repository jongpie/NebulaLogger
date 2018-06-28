public without sharing class LogglyLogPush implements Database.Batchable<Log__c>, Database.AllowsCallouts {

    private static final LoggerIntegration__mdt SETTINGS = [SELECT BaseUrl__c, ApiToken__c FROM LoggerIntegration__mdt WHERE DeveloperName = 'Loggly'];

    public List<Log__c> start(Database.BatchableContext batchableContext) {
        return (List<Log__c>)Database.query(this.getQuery());
    }

    public void execute(Database.BatchableContext batchableContext, List<Log__c> logs) {
        List<String> logEntryStrings = new List<String>();
        for(Log__c log : logs) {
            for(LogEntry__c logEntry : log.LogEntries__r) {
                LogDto convertedLogEntry = this.convertLogEntry(log, logEntry);
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
        Integer countOfRemainingLogEntries = Database.countQuery(this.getCountQuery());
        if(countOfRemainingLogEntries > 0) Database.executeBatch(new LogglyLogPush());
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
            + ' WHERE ' + Schema.Log__c.PushToLoggly__c + ' = true'
            + ' AND ' + Schema.Log__c.PushedToLogglyDate__c + ' = null';
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
            String.valueOf(Schema.LogEntry__c.ExceptionStackTrace__c), String.valueOf(Schema.LogEntry__c.ExceptionType__c),
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

    private String getFormattedTimestamp(Datetime timestamp) {
        return timestamp.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'', 'Greenwich Mean Time');
    }

    private LogDto convertLogEntry(Log__c parentLog, LogEntry__c logEntry) {
        UserDto user = new UserDto();
        user.id        = parentLog.LoggedBy__c;
        user.name      = parentLog.LoggedBy__r.Name;
        user.profileId = UserInfo.getProfileId();

        OrganizationDto organization = new OrganizationDto();
        organization.id   = UserInfo.getOrganizationId();
        organization.name = UserInfo.getOrganizationName();

        LogDto log = new LogDto();
        log.classname           = logEntry.ClassName__c;
        log.exceptionstacktrace = logEntry.ExceptionStackTrace__c;
        log.exceptiontype       = logEntry.ExceptionType__c;
        log.location            = logEntry.Source__c;
        log.logentryid          = logEntry.Id;
        log.logid               = logEntry.Log__c;
        log.logType             = logEntry.Type__c;
        log.message             = logEntry.Message__c;
        log.methodname          = logEntry.MethodName__c;
        log.organization        = organization;
        log.timestamp           = this.getFormattedTimestamp(logEntry.Timestamp__c);
        log.transactionentryid  = logEntry.TransactionEntryId__c;
        log.transactionid       = parentLog.TransactionId__c;
        log.user                = user;

        return log;
    }

    private class LogDto {
        public String className;
        public String exceptionStackTrace;
        public String exceptionType;
        public String location;
        public Id logId;
        public Id logEntryId;
        public String logType;
        public String message;
        public String methodName;
        public OrganizationDto organization;
        public String timestamp;
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