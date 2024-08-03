@IsTest
private class LoggerRestResource_Tests {
    @IsTest
    static void it_throws_an_exception_for_unknown_endpoint_on_get() {
        String unknownEndpoint = '/some-endpoint-that-definitely-should-not-exist';
        String someParameters = '/?i-hope=true';
        System.RestContext.request = new System.RestRequest();
        System.RestContext.request.requestUri = LoggerRestResource.REQUEST_URI_BASE + unknownEndpoint + someParameters;

        LoggerRestResource.handleGet();

        System.Assert.areEqual(404, System.RestContext.response.statusCode);
        System.Assert.areEqual('application/json', System.RestContext.response.headers.get('Content-Type'));
        System.Assert.isNotNull(System.RestContext.response.responseBody);
        LoggerRestResource.EndpointResponse endpointResponse = (LoggerRestResource.EndpointResponse) System.JSON.deserialize(
            System.RestContext.response.responseBody.toString(),
            LoggerRestResource.EndpointResponse.class
        );
        System.Assert.isFalse(endpointResponse.isSuccess);
        System.Assert.areEqual(1, endpointResponse.errors.size());
        System.Assert.areEqual('Unknown endpoint provided: ' + unknownEndpoint, endpointResponse.errors.get(0).message);
    }

    @IsTest
    static void it_throws_an_exception_for_unknown_endpoint_on_post() {
        String unknownEndpoint = '/some-endpoint-that-definitely-should-not-exist';
        String someParameters = '/?i-hope=true';
        System.RestContext.request = new System.RestRequest();
        System.RestContext.request.requestUri = LoggerRestResource.REQUEST_URI_BASE + unknownEndpoint + someParameters;

        LoggerRestResource.handlePost();

        System.Assert.areEqual(404, System.RestContext.response.statusCode);
        System.Assert.areEqual('application/json', System.RestContext.response.headers.get('Content-Type'));
        System.Assert.isNotNull(System.RestContext.response.responseBody);
        LoggerRestResource.EndpointResponse endpointResponse = (LoggerRestResource.EndpointResponse) System.JSON.deserialize(
            System.RestContext.response.responseBody.toString(),
            LoggerRestResource.EndpointResponse.class
        );
        System.Assert.isFalse(endpointResponse.isSuccess);
        System.Assert.areEqual(1, endpointResponse.errors.size());
        System.Assert.areEqual('Unknown endpoint provided: ' + unknownEndpoint, endpointResponse.errors.get(0).message);
    }

    @IsTest
    static void it_throws_an_exception_when_no_json_data_is_posted() {
        System.RestContext.request = new System.RestRequest();
        System.RestContext.request.requestBody = null;
        System.RestContext.request.requestUri = LoggerRestResource.REQUEST_URI_BASE + '/log';

        LoggerRestResource.handlePost();

        System.Assert.areEqual(400, System.RestContext.response.statusCode);
        System.Assert.areEqual('application/json', System.RestContext.response.headers.get('Content-Type'));
        System.Assert.isNotNull(System.RestContext.response.responseBody);
        LoggerRestResource.EndpointResponse endpointResponse = (LoggerRestResource.EndpointResponse) System.JSON.deserialize(
            System.RestContext.response.responseBody.toString(),
            LoggerRestResource.EndpointResponse.class
        );
        System.Assert.isFalse(endpointResponse.isSuccess);
        System.Assert.areEqual(1, endpointResponse.errors.size());
        System.Assert.areEqual('No data provided', endpointResponse.errors.get(0).message);
        System.Assert.areEqual(System.IllegalArgumentException.class.getName(), endpointResponse.errors.get(0).type);
    }

    @IsTest
    static void it_throws_an_exception_when_null_log_entries_list_is_posted() {
        LoggerRestResource.LogCreateRequest logCreateRequest = new LoggerRestResource.LogCreateRequest();
        logCreateRequest.logEntries = null;
        System.Assert.isNull(logCreateRequest.logEntries);
        System.RestContext.request = new System.RestRequest();
        System.RestContext.request.requestBody = System.Blob.valueOf(System.JSON.serialize(logCreateRequest));
        System.RestContext.request.requestUri = LoggerRestResource.REQUEST_URI_BASE + '/log';

        LoggerRestResource.handlePost();

        System.Assert.areEqual(400, System.RestContext.response.statusCode);
        System.Assert.areEqual('application/json', System.RestContext.response.headers.get('Content-Type'));
        System.Assert.isNotNull(System.RestContext.response.responseBody);
        LoggerRestResource.EndpointResponse endpointResponse = (LoggerRestResource.EndpointResponse) System.JSON.deserialize(
            System.RestContext.response.responseBody.toString(),
            LoggerRestResource.EndpointResponse.class
        );
        System.Assert.isFalse(endpointResponse.isSuccess);
        System.Assert.areEqual(1, endpointResponse.errors.size());
        System.Assert.areEqual('No log entries provided', endpointResponse.errors.get(0).message);
        System.Assert.areEqual(System.IllegalArgumentException.class.getName(), endpointResponse.errors.get(0).type);
    }

    @IsTest
    static void it_throws_an_exception_when_empty_log_entries_list_is_posted() {
        LoggerRestResource.LogCreateRequest logCreateRequest = new LoggerRestResource.LogCreateRequest();
        System.Assert.isTrue(logCreateRequest.logEntries.isEmpty());
        System.RestContext.request = new System.RestRequest();
        System.RestContext.request.requestBody = System.Blob.valueOf(System.JSON.serialize(logCreateRequest));
        System.RestContext.request.requestUri = LoggerRestResource.REQUEST_URI_BASE + '/log';

        LoggerRestResource.handlePost();

        System.Assert.areEqual(400, System.RestContext.response.statusCode);
        System.Assert.areEqual('application/json', System.RestContext.response.headers.get('Content-Type'));
        System.Assert.isNotNull(System.RestContext.response.responseBody);
        LoggerRestResource.EndpointResponse endpointResponse = (LoggerRestResource.EndpointResponse) System.JSON.deserialize(
            System.RestContext.response.responseBody.toString(),
            LoggerRestResource.EndpointResponse.class
        );
        System.Assert.isFalse(endpointResponse.isSuccess);
        System.Assert.areEqual(1, endpointResponse.errors.size());
        System.Assert.areEqual('No log entries provided', endpointResponse.errors.get(0).message);
        System.Assert.areEqual(System.IllegalArgumentException.class.getName(), endpointResponse.errors.get(0).type);
    }

    @IsTest
    static void it_should_successsfully_save_when_log_request_with_log_entries_is_posted() {
        LoggerRestResource.LogEntryCreateRequest firstLogEntryCreateRequest = new LoggerRestResource.LogEntryCreateRequest();
        firstLogEntryCreateRequest.loggingLevel = System.LoggingLevel.INFO.name();
        firstLogEntryCreateRequest.message = 'some message for INFO';
        firstLogEntryCreateRequest.timestamp = System.now().addDays(-1);
        LoggerRestResource.LogEntryCreateRequest secondLogEntryCreateRequest = new LoggerRestResource.LogEntryCreateRequest();
        secondLogEntryCreateRequest.loggingLevel = System.LoggingLevel.WARN.name();
        secondLogEntryCreateRequest.message = 'some message for WARN';
        secondLogEntryCreateRequest.timestamp = System.now().addDays(-1);
        LoggerRestResource.LogCreateRequest logCreateRequest = new LoggerRestResource.LogCreateRequest();
        logCreateRequest.logEntries.add(firstLogEntryCreateRequest);
        logCreateRequest.logEntries.add(secondLogEntryCreateRequest);
        System.RestContext.request = new System.RestRequest();
        System.RestContext.request.requestBody = System.Blob.valueOf(System.JSON.serialize(logCreateRequest));
        System.RestContext.request.requestUri = LoggerRestResource.REQUEST_URI_BASE + '/log';

        LoggerRestResource.handlePost();
        System.Test.getEventBus().deliver();

        System.Assert.areEqual(200, System.RestContext.response.statusCode);
        System.Assert.areEqual('application/json', System.RestContext.response.headers.get('Content-Type'));
        System.Assert.isNotNull(System.RestContext.response.responseBody);
        LoggerRestResource.EndpointResponse endpointResponse = (LoggerRestResource.EndpointResponse) System.JSON.deserialize(
            System.RestContext.response.responseBody.toString(),
            LoggerRestResource.EndpointResponse.class
        );
        System.Assert.isTrue(endpointResponse.isSuccess);
        System.Assert.areEqual(0, endpointResponse.errors.size());
        System.Assert.areEqual(System.Request.getCurrent().getRequestId(), endpointResponse.requestId);
        System.Assert.areEqual(Nebula.Logger.getTransactionId(), endpointResponse.transactionId);
        Nebula__Log__c log = [SELECT Id, Nebula__TransactionId__c FROM Nebula__Log__c];
        System.Assert.areEqual(Nebula.Logger.getTransactionId(), log.Nebula__TransactionId__c);
        Nebula__LogEntry__c firstLogEntry = [
            SELECT Id, Nebula__LoggingLevel__c, Nebula__Message__c, Nebula__Timestamp__c, Nebula__TransactionEntryNumber__c
            FROM Nebula__LogEntry__c
            WHERE Nebula__Log__c = :log.Id AND Nebula__LoggingLevel__c = :firstLogEntryCreateRequest.loggingLevel
        ];
        System.Assert.areEqual(firstLogEntryCreateRequest.loggingLevel, firstLogEntry.Nebula__LoggingLevel__c);
        System.Assert.areEqual(firstLogEntryCreateRequest.message, firstLogEntry.Nebula__Message__c);
        // System.Assert.areEqual(firstLogEntryCreateRequest.timestamp, firstLogEntry.Nebula__Timestamp__c);
        System.Assert.areEqual(1, firstLogEntry.Nebula__TransactionEntryNumber__c);
        Nebula__LogEntry__c secondLogEntry = [
            SELECT Id, Nebula__LoggingLevel__c, Nebula__Message__c, Nebula__Timestamp__c, Nebula__TransactionEntryNumber__c
            FROM Nebula__LogEntry__c
            WHERE Nebula__Log__c = :log.Id AND Nebula__LoggingLevel__c = :secondLogEntryCreateRequest.loggingLevel
        ];
        System.Assert.areEqual(secondLogEntryCreateRequest.loggingLevel, secondLogEntry.Nebula__LoggingLevel__c);
        System.Assert.areEqual(secondLogEntryCreateRequest.message, secondLogEntry.Nebula__Message__c);
        // System.Assert.areEqual(secondLogEntryCreateRequest.timestamp, secondLogEntry.Nebula__Timestamp__c);
        System.Assert.areEqual(2, secondLogEntry.Nebula__TransactionEntryNumber__c);
    }

    @IsTest
    static void it_sets_parent_log_transaction_id_when_provided() {
        Nebula__Log__c parentLog = new Nebula__Log__c(Nebula__TransactionId__c = 'some fake parent transaction id');
        insert parentLog;
        LoggerRestResource.LogEntryCreateRequest logEntryCreateRequest = new LoggerRestResource.LogEntryCreateRequest();
        logEntryCreateRequest.loggingLevel = System.LoggingLevel.INFO.name();
        logEntryCreateRequest.message = 'some message';
        logEntryCreateRequest.timestamp = System.now().addDays(-1);
        LoggerRestResource.LogCreateRequest logCreateRequest = new LoggerRestResource.LogCreateRequest();
        logCreateRequest.logEntries.add(logEntryCreateRequest);
        logCreateRequest.parentLogTransactionId = parentLog.Nebula__TransactionId__c;
        System.RestContext.request = new System.RestRequest();
        System.RestContext.request.requestBody = System.Blob.valueOf(System.JSON.serialize(logCreateRequest));
        System.RestContext.request.requestUri = LoggerRestResource.REQUEST_URI_BASE + '/log';

        LoggerRestResource.handlePost();
        System.Test.getEventBus().deliver();

        System.Assert.areEqual(200, System.RestContext.response.statusCode);
        System.Assert.areEqual('application/json', System.RestContext.response.headers.get('Content-Type'));
        System.Assert.isNotNull(System.RestContext.response.responseBody);
        LoggerRestResource.EndpointResponse endpointResponse = (LoggerRestResource.EndpointResponse) System.JSON.deserialize(
            System.RestContext.response.responseBody.toString(),
            LoggerRestResource.EndpointResponse.class
        );
        System.Assert.isTrue(endpointResponse.isSuccess);
        System.Assert.areEqual(0, endpointResponse.errors.size());
        System.Assert.areEqual(System.Request.getCurrent().getRequestId(), endpointResponse.requestId);
        System.Assert.areEqual(Nebula.Logger.getTransactionId(), endpointResponse.transactionId);
        Nebula__Log__c log = [SELECT Id, Nebula__ParentLog__c, Nebula__TransactionId__c FROM Nebula__Log__c WHERE Id != :parentLog.Id];
        System.Assert.areEqual(parentLog.Id, log.Nebula__ParentLog__c);
        System.Assert.areEqual(Nebula.Logger.getTransactionId(), log.Nebula__TransactionId__c);
    }

    @IsTest
    static void it_sets_scenario_when_provided() {
        LoggerRestResource.LogEntryCreateRequest logEntryCreateRequest = new LoggerRestResource.LogEntryCreateRequest();
        logEntryCreateRequest.loggingLevel = System.LoggingLevel.INFO.name();
        logEntryCreateRequest.message = 'some message';
        logEntryCreateRequest.timestamp = System.now().addDays(-1);
        LoggerRestResource.LogCreateRequest logCreateRequest = new LoggerRestResource.LogCreateRequest();
        logCreateRequest.logEntries.add(logEntryCreateRequest);
        logCreateRequest.scenario = 'some scenario';
        System.RestContext.request = new System.RestRequest();
        System.RestContext.request.requestBody = System.Blob.valueOf(System.JSON.serialize(logCreateRequest));
        System.RestContext.request.requestUri = LoggerRestResource.REQUEST_URI_BASE + '/log';

        LoggerRestResource.handlePost();
        System.Test.getEventBus().deliver();

        System.Assert.areEqual(200, System.RestContext.response.statusCode);
        System.Assert.areEqual('application/json', System.RestContext.response.headers.get('Content-Type'));
        System.Assert.isNotNull(System.RestContext.response.responseBody);
        LoggerRestResource.EndpointResponse endpointResponse = (LoggerRestResource.EndpointResponse) System.JSON.deserialize(
            System.RestContext.response.responseBody.toString(),
            LoggerRestResource.EndpointResponse.class
        );
        System.Assert.isTrue(endpointResponse.isSuccess);
        System.Assert.areEqual(0, endpointResponse.errors.size());
        System.Assert.areEqual(System.Request.getCurrent().getRequestId(), endpointResponse.requestId);
        System.Assert.areEqual(Nebula.Logger.getTransactionId(), endpointResponse.transactionId);
        Nebula__Log__c log = [SELECT Id, Nebula__TransactionScenario__r.Name FROM Nebula__Log__c];
        System.Assert.areEqual(logCreateRequest.scenario, log.Nebula__TransactionScenario__r.Name);
        List<Nebula__LogEntry__c> logEntries = [SELECT Id, Nebula__EntryScenario__r.Name FROM Nebula__LogEntry__c];
        System.Assert.areEqual(logCreateRequest.logEntries.size(), logEntries.size());
        for (Nebula__LogEntry__c logEntry : logEntries) {
            System.Assert.areEqual(logCreateRequest.scenario, logEntry.Nebula__EntryScenario__r.Name);
        }
    }

    @IsTest
    static void it_sets_related_record_id_when_provided() {
        String recordId = System.UserInfo.getUserId();
        LoggerRestResource.LogEntryCreateRequest logEntryCreateRequest = new LoggerRestResource.LogEntryCreateRequest();
        logEntryCreateRequest.loggingLevel = System.LoggingLevel.INFO.name();
        logEntryCreateRequest.message = 'some message';
        logEntryCreateRequest.relatedRecordId = recordId;
        logEntryCreateRequest.timestamp = System.now().addDays(-1);
        LoggerRestResource.LogCreateRequest logCreateRequest = new LoggerRestResource.LogCreateRequest();
        logCreateRequest.logEntries.add(logEntryCreateRequest);
        System.RestContext.request = new System.RestRequest();
        System.RestContext.request.requestBody = System.Blob.valueOf(System.JSON.serialize(logCreateRequest));
        System.RestContext.request.requestUri = LoggerRestResource.REQUEST_URI_BASE + '/log';

        LoggerRestResource.handlePost();
        System.Test.getEventBus().deliver();

        System.Assert.areEqual(200, System.RestContext.response.statusCode);
        System.Assert.areEqual('application/json', System.RestContext.response.headers.get('Content-Type'));
        System.Assert.isNotNull(System.RestContext.response.responseBody);
        LoggerRestResource.EndpointResponse endpointResponse = (LoggerRestResource.EndpointResponse) System.JSON.deserialize(
            System.RestContext.response.responseBody.toString(),
            LoggerRestResource.EndpointResponse.class
        );
        System.Assert.isTrue(endpointResponse.isSuccess);
        System.Assert.areEqual(0, endpointResponse.errors.size());
        System.Assert.areEqual(System.Request.getCurrent().getRequestId(), endpointResponse.requestId);
        System.Assert.areEqual(Nebula.Logger.getTransactionId(), endpointResponse.transactionId);
        Nebula__LogEntry__c logEntry = [
            SELECT Id, Nebula__RecordId__c
            FROM Nebula__LogEntry__c
            WHERE Nebula__Log__r.Nebula__TransactionId__c = :endpointResponse.transactionId
        ];
        System.Assert.areEqual(logEntryCreateRequest.relatedRecordId, logEntry.Nebula__RecordId__c);
    }

    @IsTest
    static void it_stores_tags_when_provided() {
        LoggerRestResource.LogEntryCreateRequest logEntryCreateRequest = new LoggerRestResource.LogEntryCreateRequest();
        logEntryCreateRequest.loggingLevel = System.LoggingLevel.INFO.name();
        logEntryCreateRequest.message = 'some message';
        logEntryCreateRequest.timestamp = System.now().addDays(-1);
        logEntryCreateRequest.tags = new List<String>{ 'some tag', 'another tag' };
        LoggerRestResource.LogCreateRequest logCreateRequest = new LoggerRestResource.LogCreateRequest();
        logCreateRequest.logEntries.add(logEntryCreateRequest);
        System.RestContext.request = new System.RestRequest();
        System.RestContext.request.requestBody = System.Blob.valueOf(System.JSON.serialize(logCreateRequest));
        System.RestContext.request.requestUri = LoggerRestResource.REQUEST_URI_BASE + '/log';

        LoggerRestResource.handlePost();
        System.Test.getEventBus().deliver();

        System.Assert.areEqual(200, System.RestContext.response.statusCode);
        System.Assert.areEqual('application/json', System.RestContext.response.headers.get('Content-Type'));
        System.Assert.isNotNull(System.RestContext.response.responseBody);
        LoggerRestResource.EndpointResponse endpointResponse = (LoggerRestResource.EndpointResponse) System.JSON.deserialize(
            System.RestContext.response.responseBody.toString(),
            LoggerRestResource.EndpointResponse.class
        );
        Nebula__LogEntry__c logEntry = [
            SELECT Id, (SELECT Id, Nebula__Tag__r.Name FROM Nebula__LogEntryTags__r)
            FROM Nebula__LogEntry__c
        ];
        System.Assert.areEqual(logEntryCreateRequest.tags.size(), logEntry.Nebula__LogEntryTags__r.size());
        Set<String> providedTags = new Set<String>(logEntryCreateRequest.tags);
        for (Nebula__LogEntryTag__c logEntryTag : logEntry.Nebula__LogEntryTags__r) {
            System.Assert.isTrue(providedTags.contains(logEntryTag.Nebula__Tag__r.Name));
        }
    }
}
