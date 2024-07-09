@IsTest
private class LoggerRestResource_Tests {
    // Lovingly borrowed from Joys of Apex - https://www.jamessimone.net/blog/joys-of-apex/extendable-apis/
    @IsTest
    static void it_should_resolve_api_route_with_trailing_slash() {
        String versionNumber = 'v1';
        String endpointName = 'ORDERS';
        System.RestRequest restRequest = new System.RestRequest();
        restRequest.requestURI = '/services/apexrest/logger/' + versionNumber + '/' + endpointName + '/';

        LoggerRestResource.ApiRequestResolver resolver = new LoggerRestResource.ApiRequestResolver(restRequest);

        System.Assert.areEqual(versionNumber, resolver.ApiVersionNumber);
        System.Assert.areEqual(endpointName.toLowerCase(), resolver.ApiName);
        // System.Assert.areEqual('', resolver.RequestUrlBody);
    }

    @IsTest
    static void it_should_resolve_api_route_without_trailing_slash() {
        String versionNumber = 'v1';
        String endpointName = 'ORDERS';
        System.RestRequest restRequest = new System.RestRequest();
        restRequest.requestURI = '/services/apexrest/logger/' + versionNumber + '/' + endpointName + '/';

        LoggerRestResource.ApiRequestResolver resolver = new LoggerRestResource.ApiRequestResolver(restRequest);

        System.Assert.areEqual(versionNumber, resolver.ApiVersionNumber);
        System.Assert.areEqual(endpointName.toLowerCase(), resolver.ApiName);
        // System.Assert.areEqual('', resolver.RequestUrlBody);
    }

    // @IsTest
    // static void it_should_resolve_api_route_with_url_parameter() {
    //     String versionNumber = 'v1';
    //     String endpointName = 'ORDERS';
    //     String someParameterValue = 'someValue';
    //     System.RestRequest restRequest = new System.RestRequest();
    //     restRequest.requestURI = '/services/apexrest/logger/' + versionNumber + '/' + endpointName + '/' + someParameterValue;

    //     LoggerRestResource.ApiRequestResolver resolver = new LoggerRestResource.ApiRequestResolver(restRequest);

    //     System.Assert.areEqual(versionNumber, resolver.ApiVersionNumber);
    //     System.Assert.areEqual(endpointName.toLowerCase(), resolver.ApiName);
    //     // System.Assert.areEqual(someParameterValue, resolver.RequestUrlBody);
    // }

    @IsTest
    static void it_throws_an_exception_when_an_invalid_version_number_is_specified() {
        String invalidVersionNumber = 'v0-this-is-not-valid';
        System.RestContext.request = new System.RestRequest();
        System.RestContext.request.requestURI = '/services/apexrest/logger/' + invalidVersionNumber + '/save';
        System.Exception thrownException = null;

        try {
            LoggerRestResource.handlePost();
            System.Assert.fail('Exception expected on previous line');
        } catch(System.IllegalArgumentException ex) {
            thrownException = ex;
        }

        System.Assert.isNotNull(thrownException);
        System.Assert.isInstanceOfType(thrownException, System.IllegalArgumentException.class);
        System.Assert.areEqual('Unknown version number specified for logger REST resource: ' + invalidVersionNumber, thrownException.getMessage());
    }

    @IsTest
    static void it_should_resolve_request_body() {
        String body = '{}';
        System.RestRequest restRequest = new System.RestRequest();
        restRequest.requestURI = '/services/apexrest/logger/v1/some-endpoint';
        restRequest.requestBody = Blob.valueOf(body);

        LoggerRestResource.ApiRequestResolver resolver = new LoggerRestResource.ApiRequestResolver(restRequest);

        System.Assert.areEqual(body, resolver.RequestBody);
    }

    @IsTest
    static void it_throws_an_exception_when_no_json_data_is_posted() {
        System.RestContext.request = new System.RestRequest();
        System.RestContext.request.requestURI = '/services/apexrest/logger/v1/save';
        System.RestContext.request.requestBody = null;
        System.Exception thrownException = null;

        try {
            LoggerRestResource.handlePost();
            System.Assert.fail('Exception expected on previous line');
        } catch(System.IllegalArgumentException ex) {
            thrownException = ex;
        }

        System.Assert.isNotNull(thrownException);
        System.Assert.isInstanceOfType(thrownException, System.IllegalArgumentException.class);
        System.Assert.areEqual('No data provided', thrownException.getMessage());
    }

    @IsTest
    static void it_should_successsfully_save_log_request() {
        LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
        LoggerRestResource.LogEntryRequest logEntryRequest = new LoggerRestResource.LogEntryRequest();
        logEntryRequest.loggingLevelName = System.LoggingLevel.INFO.name();
        logEntryRequest.message = 'some message';
        logEntryRequest.timestamp = System.now();
        LoggerRestResource.LogRequest logRequest = new LoggerRestResource.LogRequest();
        logRequest.logEntries.add(logEntryRequest);
        System.RestContext.request = new System.RestRequest();
        System.RestContext.request.requestURI = '/services/apexrest/logger/v1/save';
        System.RestContext.request.requestBody = System.Blob.valueOf(System.JSON.serialize(logRequest));

        LoggerRestResource.handlePost();

        LoggerRestResource.LogResponse logResponse = (LoggerRestResource.LogResponse) System.JSON.deserialize(
            System.RestContext.response.responseBody.toString(),
            LoggerRestResource.LogResponse.class
        );
        // System.Assert.isTrue(logResponse.isSuccess);
        System.Assert.areEqual(Logger.getTransactionId(), logResponse.transactionId);
        System.Assert.areEqual(Logger.getSaveMethod().name(), logResponse.saveMethodName);
        System.Assert.isNull(logResponse.parentLogTransactionId);
        System.Assert.areEqual(1, Logger.saveLogCallCount);
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
        System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
        LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
        System.Assert.areEqual(logEntryRequest.loggingLevelName, publishedLogEntryEvent.LoggingLevel__c);
        System.Assert.areEqual(logEntryRequest.message, publishedLogEntryEvent.Message__c);
        System.Assert.areEqual(logEntryRequest.timestamp, publishedLogEntryEvent.Timestamp__c);
        System.Assert.areEqual('Integration', publishedLogEntryEvent.OriginType__c);
        System.Assert.areEqual('Integration', publishedLogEntryEvent.OriginSourceMetadataType__c);
    }
}
