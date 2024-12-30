//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions, PMD.NcssMethodCount')
@IsTest(IsParallel=true)
private class LoggerRestResource_Tests {
  @IsTest
  static void endpoint_request_correctly_parses_system_rest_request_without_endpoint_particle() {
    String expectedEndpointName = 'some-endpoint-name';
    String expectedRequestBody = 'some string that may or may not be valid JSON (but hopefully it is)';
    System.RestRequest restRequest = new System.RestRequest();
    restRequest.addHeader('X-some-header', 'some-value');
    restRequest.addHeader('X-another-header', 'another-value');
    restRequest.addParameter('verbose', 'true');
    restRequest.addParameter('some-other-parameter', 'someValue');
    restRequest.requestBody = Blob.valueOf(expectedRequestBody);
    restRequest.requestUri = LoggerRestResource.REQUEST_URI_BASE + '/' + expectedEndpointName + '/';

    LoggerRestResource.EndpointRequest endpointRequest = new LoggerRestResource.EndpointRequest(restRequest);

    System.Assert.areEqual(expectedRequestBody, endpointRequest.body);
    System.Assert.areEqual(expectedEndpointName, endpointRequest.name);
    System.Assert.isNull(endpointRequest.particle);
    System.Assert.areEqual(new List<String>(restRequest.headers.keySet()), endpointRequest.headerKeys);
    System.Assert.areEqual(restRequest.params, endpointRequest.parameters);
    System.Assert.areEqual(restRequest.requestUri, endpointRequest.uri);
  }

  @IsTest
  static void endpoint_request_correctly_parses_system_rest_request_with_endpoint_particle() {
    String expectedEndpointName = 'some-endpoint-name';
    String expectedEndpointParticle = System.UUID.randomUUID().toString();
    String expectedRequestBody = 'some string that may or may not be valid JSON (but hopefully it is)';
    System.RestRequest restRequest = new System.RestRequest();
    restRequest.addHeader('X-some-header', 'some-value');
    restRequest.addHeader('X-another-header', 'another-value');
    restRequest.addParameter('verbose', 'true');
    restRequest.addParameter('some-other-parameter', 'someValue');
    restRequest.requestBody = Blob.valueOf(expectedRequestBody);
    restRequest.requestUri = LoggerRestResource.REQUEST_URI_BASE + '/' + expectedEndpointName + '/' + expectedEndpointParticle;

    LoggerRestResource.EndpointRequest endpointRequest = new LoggerRestResource.EndpointRequest(restRequest);

    System.Assert.areEqual(expectedRequestBody, endpointRequest.body);
    System.Assert.areEqual(expectedEndpointName, endpointRequest.name);
    System.Assert.areEqual(expectedEndpointParticle, endpointRequest.particle);
    System.Assert.areEqual(new List<String>(restRequest.headers.keySet()), endpointRequest.headerKeys);
    System.Assert.areEqual(restRequest.params, endpointRequest.parameters);
    System.Assert.areEqual(restRequest.requestUri, endpointRequest.uri);
  }

  @IsTest
  static void unknown_endpoint_post_throws_an_exception() {
    String unknownEndpoint = 'some-endpoint-that-definitely-should-not-exist';
    String someParameters = '/?i-hope=true';
    System.RestContext.request = new System.RestRequest();
    System.RestContext.request.requestUri = LoggerRestResource.REQUEST_URI_BASE + '/' + unknownEndpoint + someParameters;

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
  static void otel_severity_text_correctly_maps_to_logging_level() {
    Map<String, System.LoggingLevel> otelSeverityTextToExpectedLoggingLevel = new Map<String, System.LoggingLevel>{
      'Error' => System.LoggingLevel.ERROR,
      'Warn' => System.LoggingLevel.WARN,
      'Info' => System.LoggingLevel.INFO,
      'Debug' => System.LoggingLevel.DEBUG,
      'Trace3' => System.LoggingLevel.FINE,
      'Trace2' => System.LoggingLevel.FINER,
      'Trace' => System.LoggingLevel.FINEST,
      'Anything else' => System.LoggingLevel.DEBUG
    };
    for (String otelSeverityText : otelSeverityTextToExpectedLoggingLevel.keySet()) {
      LoggerRestResource.OTelLogRecord otelLogEntry = new LoggerRestResource.OTelLogRecord();

      otelLogEntry.severityText = otelSeverityText;

      System.LoggingLevel expectedLoggingLevel = otelSeverityTextToExpectedLoggingLevel.get(otelSeverityText);
      System.Assert.areEqual(expectedLoggingLevel.name(), otelLogEntry.getLogEntryEvent().LoggingLevel__c);
      System.Assert.areEqual(expectedLoggingLevel.ordinal(), otelLogEntry.getLogEntryEvent().LoggingLevelOrdinal__c);
    }
  }

  @IsTest
  static void logs_endpoint_post_throws_an_exception_when_null_log_entries_list_is_provided() {
    System.RestContext.request = new System.RestRequest();
    System.RestContext.request.requestBody = null;
    System.RestContext.request.requestUri = LoggerRestResource.REQUEST_URI_BASE + '/logs';

    LoggerRestResource.handlePost();

    System.Assert.areEqual(LoggerRestResource.STATUS_CODE_400_BAD_REQUEST, System.RestContext.response.statusCode);
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
  static void logs_endpoint_post_successsfully_saves_otel_log_when_data_is_provided() {
    // This test method is... incredibly long. The work is "simple", it's "just" creating a bunch of OTel attributes
    // and validating that they map to the correct LogEntryEvent__e fields. But the lines of code is a lot...
    // TODO revisit to see if there's a way to shorten this up/make it more readable
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
    LoggerRestResource.OTelLogRecord otelLogEntry = new LoggerRestResource.OTelLogRecord();
    otelLogEntry.body = new LoggerRestResource.OTelAttributeValue('some message');
    otelLogEntry.name = 'Some span name, which maps to Nebula Logger\'s scenario name';
    otelLogEntry.severityText = 'Info';
    // otelLogEntry.spanId = 'TODO';
    otelLogEntry.timeUnixNano = (System.now().getTime() * 1000000).toString();
    otelLogEntry.traceId = System.UUID.randomUUID().toString().replace('-', '').toLowerCase();
    LoggerRestResource.OTelAttribute browserAddressAttribute = new LoggerRestResource.OTelAttribute('browser.address', 'some browser address');
    otelLogEntry.attributes.add(browserAddressAttribute);
    LoggerRestResource.OTelAttribute browserFormFactorAttribute = new LoggerRestResource.OTelAttribute('browser.form_factor', 'some browser form factor');
    otelLogEntry.attributes.add(browserFormFactorAttribute);
    LoggerRestResource.OTelAttribute browserLanguageAttribute = new LoggerRestResource.OTelAttribute('browser.language', 'some browser language');
    otelLogEntry.attributes.add(browserLanguageAttribute);
    LoggerRestResource.OTelAttribute browserScreenResolutionAttribute = new LoggerRestResource.OTelAttribute(
      'browser.screen_resolution',
      'some browser screen resolution'
    );
    otelLogEntry.attributes.add(browserScreenResolutionAttribute);
    LoggerRestResource.OTelAttribute browserUserAgentAttribute = new LoggerRestResource.OTelAttribute('browser.user_agent', 'some browser user agent');
    otelLogEntry.attributes.add(browserUserAgentAttribute);
    LoggerRestResource.OTelAttribute browserWindowResolutionAttribute = new LoggerRestResource.OTelAttribute(
      'browser.window_resolution',
      'some browser window resolution'
    );
    otelLogEntry.attributes.add(browserWindowResolutionAttribute);
    LoggerRestResource.OTelAttribute exceptionMessageAttribute = new LoggerRestResource.OTelAttribute('exception.message', 'some exception message');
    otelLogEntry.attributes.add(exceptionMessageAttribute);
    LoggerRestResource.OTelAttribute exceptionStackTraceAttribute = new LoggerRestResource.OTelAttribute('exception.stack_trace', 'Some.Exception.stackTrace');
    otelLogEntry.attributes.add(exceptionStackTraceAttribute);
    LoggerRestResource.OTelAttribute exceptionTypeAttribute = new LoggerRestResource.OTelAttribute('exception.type', 'SomeExceptionType');
    otelLogEntry.attributes.add(exceptionTypeAttribute);
    LoggerRestResource.OTelAttribute httpRequestBodyAttribute = new LoggerRestResource.OTelAttribute('http_request.body', 'some value for http_request.body');
    otelLogEntry.attributes.add(httpRequestBodyAttribute);
    LoggerRestResource.OTelAttribute httpRequestBodyMaskedAttribute = new LoggerRestResource.OTelAttribute('http_request.body_masked', true);
    otelLogEntry.attributes.add(httpRequestBodyMaskedAttribute);
    LoggerRestResource.OTelAttribute httpRequestCompressedAttribute = new LoggerRestResource.OTelAttribute('http_request.compressed', false);
    otelLogEntry.attributes.add(httpRequestCompressedAttribute);
    LoggerRestResource.OTelAttribute httpRequestEndpointAttribute = new LoggerRestResource.OTelAttribute(
      'http_request.endpoint',
      'some value for http_request.endpoint'
    );
    otelLogEntry.attributes.add(httpRequestEndpointAttribute);
    LoggerRestResource.OTelAttribute httpRequestHeaderKeysAttribute = new LoggerRestResource.OTelAttribute(
      'http_request.header_keys',
      'some value for http_request.header_keys'
    );
    otelLogEntry.attributes.add(httpRequestHeaderKeysAttribute);
    LoggerRestResource.OTelAttribute httpRequestHeadersAttribute = new LoggerRestResource.OTelAttribute(
      'http_request.headers',
      'some value for http_request.headers'
    );
    otelLogEntry.attributes.add(httpRequestHeadersAttribute);
    LoggerRestResource.OTelAttribute httpRequestMethodAttribute = new LoggerRestResource.OTelAttribute(
      'http_request.method',
      'some value for http_request.method'
    );
    otelLogEntry.attributes.add(httpRequestMethodAttribute);
    LoggerRestResource.OTelAttribute httpResponseBodyAttribute = new LoggerRestResource.OTelAttribute(
      'http_response.body',
      'some value for http_response.body'
    );
    otelLogEntry.attributes.add(httpResponseBodyAttribute);
    LoggerRestResource.OTelAttribute httpResponseBodyMaskedAttribute = new LoggerRestResource.OTelAttribute('http_response.body_masked', true);
    otelLogEntry.attributes.add(httpResponseBodyMaskedAttribute);
    LoggerRestResource.OTelAttribute httpResponseHeaderKeysAttribute = new LoggerRestResource.OTelAttribute(
      'http_response.header_keys',
      'some value for http_response.header_keys'
    );
    otelLogEntry.attributes.add(httpResponseHeaderKeysAttribute);
    LoggerRestResource.OTelAttribute httpResponseHeadersAttribute = new LoggerRestResource.OTelAttribute(
      'http_response.headers',
      'some value for http_response.headers'
    );
    otelLogEntry.attributes.add(httpResponseHeadersAttribute);
    LoggerRestResource.OTelAttribute httpResponseStatusAttribute = new LoggerRestResource.OTelAttribute(
      'http_response.status',
      'some value for http_response.status'
    );
    otelLogEntry.attributes.add(httpResponseStatusAttribute);
    LoggerRestResource.OTelAttribute httpResponseStatusCodeAttribute = new LoggerRestResource.OTelAttribute('http_response.status_code', 123);
    otelLogEntry.attributes.add(httpResponseStatusCodeAttribute);
    LoggerRestResource.OTelAttribute loggedByFederationIdentifierAttribute = new LoggerRestResource.OTelAttribute(
      'logged_by.federation_identifier',
      'Some.Federation.Identifier@saml.system.sso.com.org'
    );
    otelLogEntry.attributes.add(loggedByFederationIdentifierAttribute);
    LoggerRestResource.OTelAttribute loggedByIdAttribute = new LoggerRestResource.OTelAttribute(
      'logged_by.id',
      LoggerMockDataCreator.createId(Schema.User.SObjectType)
    );
    otelLogEntry.attributes.add(loggedByIdAttribute);
    LoggerRestResource.OTelAttribute loggedByUsernameAttribute = new LoggerRestResource.OTelAttribute('logged_by.username', 'Some.Username@some.company.com');
    otelLogEntry.attributes.add(loggedByUsernameAttribute);
    LoggerRestResource.OTelAttribute originStackTraceAttribute = new LoggerRestResource.OTelAttribute('origin.stack_trace', 'Some.Origin.stackTrace');
    otelLogEntry.attributes.add(originStackTraceAttribute);
    LoggerRestResource.OTelAttribute parentLogTransactionIdAttribute = new LoggerRestResource.OTelAttribute('parent_log.transaction_id', '123-abc');
    otelLogEntry.attributes.add(parentLogTransactionIdAttribute);
    LoggerRestResource.OTelScopeLog scopeLog = new LoggerRestResource.OTelScopeLog();
    scopeLog.logRecords.add(otelLogEntry);
    LoggerRestResource.OTelResourceLog resourceLog = new LoggerRestResource.OTelResourceLog();
    LoggerRestResource.OTelAttribute resourceServiceIdAttribute = new LoggerRestResource.OTelAttribute('service.id', 'some-unique-id-value');
    resourceLog.resource.attributes.add(resourceServiceIdAttribute);
    LoggerRestResource.OTelAttribute resourceServiceNameAttribute = new LoggerRestResource.OTelAttribute(
      'service.name',
      'some-external-system-or-microservice'
    );
    resourceLog.resource.attributes.add(resourceServiceNameAttribute);
    LoggerRestResource.OTelAttribute resourceServiceTypeAttribute = new LoggerRestResource.OTelAttribute(
      'service.type',
      'some-type-of-external-system-or-microservice'
    );
    resourceLog.resource.attributes.add(resourceServiceTypeAttribute);
    LoggerRestResource.OTelAttribute resourceServiceVersionAttribute = new LoggerRestResource.OTelAttribute('service.version', 'some-version-number');
    resourceLog.resource.attributes.add(resourceServiceVersionAttribute);
    resourceLog.scopeLogs.add(scopeLog);
    LoggerRestResource.OTelLogsPayload logsPayload = new LoggerRestResource.OTelLogsPayload();
    logsPayload.resourceLogs.add(resourceLog);
    System.RestContext.request = new System.RestRequest();
    System.RestContext.request.requestBody = Blob.valueOf(System.JSON.serialize(logsPayload));
    System.RestContext.request.requestUri = LoggerRestResource.REQUEST_URI_BASE + '/logs';

    LoggerRestResource.handlePost();

    System.Assert.areEqual(
      LoggerRestResource.STATUS_CODE_201_CREATED,
      System.RestContext.response.statusCode,
      System.RestContext.response.responseBody.toString()
    );
    System.Assert.areEqual('application/json', System.RestContext.response.headers.get('Content-Type'));
    System.Assert.isNotNull(System.RestContext.response.responseBody);
    LoggerRestResource.EndpointResponse endpointResponse = (LoggerRestResource.EndpointResponse) System.JSON.deserialize(
      System.RestContext.response.responseBody.toString(),
      LoggerRestResource.EndpointResponse.class
    );
    System.Assert.isTrue(endpointResponse.isSuccess);
    System.Assert.areEqual(0, endpointResponse.errors.size());
    System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(1, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
    LogEntryEvent__e publishedLogEntryEvent = (LogEntryEvent__e) LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().get(0);
    // External Service Fields
    System.Assert.areEqual(resourceServiceIdAttribute.value.stringValue, publishedLogEntryEvent.ExternalServiceId__c);
    System.Assert.areEqual(resourceServiceNameAttribute.value.stringValue, publishedLogEntryEvent.ExternalServiceName__c);
    System.Assert.areEqual(resourceServiceTypeAttribute.value.stringValue, publishedLogEntryEvent.ExternalServiceType__c);
    System.Assert.areEqual(resourceServiceVersionAttribute.value.stringValue, publishedLogEntryEvent.ExternalServiceVersion__c);
    // Origin Fields
    System.Assert.isNull(publishedLogEntryEvent.OriginLocation__c);
    System.Assert.isNull(publishedLogEntryEvent.OriginSourceActionName__c);
    System.Assert.isNull(publishedLogEntryEvent.OriginSourceApiName__c);
    System.Assert.isNull(publishedLogEntryEvent.OriginSourceId__c);
    System.Assert.isNull(publishedLogEntryEvent.OriginSourceMetadataType__c);
    System.Assert.areEqual('External Service', publishedLogEntryEvent.OriginType__c);
    System.Assert.areEqual(otelLogEntry.severityText.toUpperCase(), publishedLogEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(otelLogEntry.body.stringValue, publishedLogEntryEvent.Message__c);
    // Limits Fields
    System.Assert.isNull(publishedLogEntryEvent.LimitsAggregateQueriesMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsAggregateQueriesUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsAsyncCallsMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsAsyncCallsUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsCalloutsMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsCalloutsUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsCpuTimeMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsCpuTimeUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsDmlRowsMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsDmlRowsUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsDmlStatementsMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsDmlStatementsUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsEmailInvocationsMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsEmailInvocationsUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsFutureCallsMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsFutureCallsUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsHeapSizeMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsHeapSizeUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsMobilePushApexCallsMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsMobilePushApexCallsUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsPublishImmediateDmlStatementsMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsPublishImmediateDmlStatementsUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsQueueableJobsMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsQueueableJobsUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsSoqlQueriesMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsSoqlQueriesUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsSoqlQueryLocatorRowsMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsSoqlQueryRowsMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsSoqlQueryRowsUsed__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsSoslSearchesMax__c);
    System.Assert.isNull(publishedLogEntryEvent.LimitsSoslSearchesUsed__c);
    // User Fields (that should not be auto-populated)
    System.Assert.isNull(publishedLogEntryEvent.Locale__c);
    System.Assert.isNull(publishedLogEntryEvent.ProfileId__c);
    System.Assert.isNull(publishedLogEntryEvent.ThemeDisplayed__c);
    System.Assert.isNull(publishedLogEntryEvent.TimeZoneId__c);
    System.Assert.isNull(publishedLogEntryEvent.TimeZoneName__c);
    System.Assert.isNull(publishedLogEntryEvent.UserLicenseDefinitionKey__c);
    System.Assert.isNull(publishedLogEntryEvent.UserLicenseId__c);
    System.Assert.isNull(publishedLogEntryEvent.UserLicenseName__c);
    System.Assert.isNull(publishedLogEntryEvent.UserRoleId__c);
    System.Assert.isNull(publishedLogEntryEvent.UserRoleName__c);
    System.Assert.isNull(publishedLogEntryEvent.UserType__c);
    // Browser Fields
    System.Assert.areEqual(browserAddressAttribute.value.stringValue, publishedLogEntryEvent.BrowserAddress__c);
    System.Assert.areEqual(browserFormFactorAttribute.value.stringValue, publishedLogEntryEvent.BrowserFormFactor__c);
    System.Assert.areEqual(browserLanguageAttribute.value.stringValue, publishedLogEntryEvent.BrowserLanguage__c);
    System.Assert.areEqual(browserScreenResolutionAttribute.value.stringValue, publishedLogEntryEvent.BrowserScreenResolution__c);
    System.Assert.areEqual(browserUserAgentAttribute.value.stringValue, publishedLogEntryEvent.BrowserUserAgent__c);
    System.Assert.areEqual(browserWindowResolutionAttribute.value.stringValue, publishedLogEntryEvent.BrowserWindowResolution__c);
    // Exception Fields
    System.Assert.areEqual(exceptionMessageAttribute.value.stringValue, publishedLogEntryEvent.ExceptionMessage__c);
    System.Assert.areEqual(exceptionStackTraceAttribute.value.stringValue, publishedLogEntryEvent.ExceptionStackTrace__c);
    System.Assert.areEqual(exceptionTypeAttribute.value.stringValue, publishedLogEntryEvent.ExceptionType__c);
    // HTTP Request Fields
    System.Assert.areEqual(httpRequestBodyMaskedAttribute.value.boolValue, publishedLogEntryEvent.HttpRequestBodyMasked__c);
    System.Assert.areEqual(httpRequestCompressedAttribute.value.boolValue, publishedLogEntryEvent.HttpRequestCompressed__c);
    System.Assert.areEqual(httpRequestEndpointAttribute.value.stringValue, publishedLogEntryEvent.HttpRequestEndpoint__c);
    System.Assert.areEqual(httpRequestHeaderKeysAttribute.value.stringValue, publishedLogEntryEvent.HttpRequestHeaderKeys__c);
    System.Assert.areEqual(httpRequestHeadersAttribute.value.stringValue, publishedLogEntryEvent.HttpRequestHeaders__c);
    System.Assert.areEqual(httpRequestMethodAttribute.value.stringValue, publishedLogEntryEvent.HttpRequestMethod__c);
    System.Assert.areEqual(httpResponseBodyAttribute.value.stringValue, publishedLogEntryEvent.HttpResponseBody__c);
    // HTTP Response Fields
    System.Assert.areEqual(httpResponseBodyMaskedAttribute.value.boolValue, publishedLogEntryEvent.HttpResponseBodyMasked__c);
    System.Assert.areEqual(httpResponseHeaderKeysAttribute.value.stringValue, publishedLogEntryEvent.HttpResponseHeaderKeys__c);
    System.Assert.areEqual(httpResponseHeadersAttribute.value.stringValue, publishedLogEntryEvent.HttpResponseHeaders__c);
    System.Assert.areEqual(httpResponseStatusAttribute.value.stringValue, publishedLogEntryEvent.HttpResponseStatus__c);
    System.Assert.areEqual(httpResponseStatusCodeAttribute.value.intValue, publishedLogEntryEvent.HttpResponseStatusCode__c);
    // Logged By Fields
    System.Assert.areEqual(loggedByFederationIdentifierAttribute.value.stringValue, publishedLogEntryEvent.LoggedByFederationIdentifier__c);
    System.Assert.areEqual(loggedByIdAttribute.value.stringValue, publishedLogEntryEvent.LoggedById__c);
    System.Assert.areEqual(loggedByUsernameAttribute.value.stringValue, publishedLogEntryEvent.LoggedByUsername__c);
    // Other Fields
    System.Assert.areEqual(parentLogTransactionIdAttribute.value.stringValue, publishedLogEntryEvent.ParentLogTransactionId__c);
    System.Assert.areEqual(originStackTraceAttribute.value.stringValue, publishedLogEntryEvent.StackTrace__c);
    Datetime expectedTimestamp = Datetime.newInstance(Long.valueOf(otelLogEntry.timeUnixNano) / 1000000);
    System.Assert.areEqual(expectedTimestamp, publishedLogEntryEvent.Timestamp__c);
    System.Assert.areEqual(otelLogEntry.name, publishedLogEntryEvent.EntryScenario__c);
    String hyphenatedUuid =
      otelLogEntry.traceId.substring(0, 8) +
      '-' +
      otelLogEntry.traceId.substring(8, 12) +
      '-' +
      otelLogEntry.traceId.substring(12, 16) +
      '-' +
      otelLogEntry.traceId.substring(16, 20) +
      '-' +
      otelLogEntry.traceId.substring(20, 32);
    String expectedTransactionId = System.UUID.fromString(hyphenatedUuid).toString();
    System.Assert.areEqual(expectedTransactionId, publishedLogEntryEvent.TransactionId__c);
    System.Assert.areEqual(1, publishedLogEntryEvent.TransactionEntryNumber__c);
  }
}
