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
    LoggerDataStore.setMock(LoggerMockDataStore.getEventBus());
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishCallCount());
    System.Assert.areEqual(0, LoggerMockDataStore.getEventBus().getPublishedPlatformEvents().size());
    LoggerRestResource.OTelLogRecord otelLogEntry = new LoggerRestResource.OTelLogRecord();
    otelLogEntry.body = new LoggerRestResource.OTelAttributeValue('some message');
    otelLogEntry.severityText = 'Info';
    otelLogEntry.timeUnixNano = '1581452773000000789';
    LoggerRestResource.OTelAttribute exceptionMessageAttribute = new LoggerRestResource.OTelAttribute('exception.message', 'some exception message');
    otelLogEntry.attributes.add(exceptionMessageAttribute);
    LoggerRestResource.OTelAttribute exceptionStackTraceAttribute = new LoggerRestResource.OTelAttribute('exception.stack_trace', 'Some.Exception.stackTrace');
    otelLogEntry.attributes.add(exceptionStackTraceAttribute);
    LoggerRestResource.OTelAttribute exceptionTypeAttribute = new LoggerRestResource.OTelAttribute('exception.type', 'SomeExceptionType');
    otelLogEntry.attributes.add(exceptionTypeAttribute);
    LoggerRestResource.OTelAttribute originStackTraceAttribute = new LoggerRestResource.OTelAttribute('origin.stack_trace', 'Some.Origin.stackTrace');
    otelLogEntry.attributes.add(originStackTraceAttribute);
    LoggerRestResource.OTelAttribute parentLogTransactionIdAttribute = new LoggerRestResource.OTelAttribute('parent_log.transaction_id', '123-abc');
    otelLogEntry.attributes.add(parentLogTransactionIdAttribute);
    LoggerRestResource.OTelScopeLog scopeLog = new LoggerRestResource.OTelScopeLog();
    scopeLog.logRecords.add(otelLogEntry);
    LoggerRestResource.OTelResourceLog resourceLog = new LoggerRestResource.OTelResourceLog();
    LoggerRestResource.OTelAttribute resourceServiceNameAttribute = new LoggerRestResource.OTelAttribute(
      'service.name',
      'some-external-system-or-microservice'
    );
    resourceLog.resource.attributes.add(resourceServiceNameAttribute);
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
    System.Assert.isNull(publishedLogEntryEvent.OriginLocation__c);
    System.Assert.areEqual(resourceServiceNameAttribute.value.stringValue, publishedLogEntryEvent.OriginServiceName__c);
    System.Assert.isNull(publishedLogEntryEvent.OriginSourceActionName__c);
    System.Assert.isNull(publishedLogEntryEvent.OriginSourceApiName__c);
    System.Assert.isNull(publishedLogEntryEvent.OriginSourceId__c);
    System.Assert.isNull(publishedLogEntryEvent.OriginSourceMetadataType__c);
    System.Assert.areEqual('API', publishedLogEntryEvent.OriginType__c);
    System.Assert.areEqual(otelLogEntry.severityText.toUpperCase(), publishedLogEntryEvent.LoggingLevel__c);
    System.Assert.areEqual(otelLogEntry.body.stringValue, publishedLogEntryEvent.Message__c);
    System.Assert.areEqual(exceptionMessageAttribute.value.stringValue, publishedLogEntryEvent.ExceptionMessage__c);
    System.Assert.areEqual(exceptionStackTraceAttribute.value.stringValue, publishedLogEntryEvent.ExceptionStackTrace__c);
    System.Assert.areEqual(exceptionTypeAttribute.value.stringValue, publishedLogEntryEvent.ExceptionType__c);
    System.Assert.areEqual(parentLogTransactionIdAttribute.value.stringValue, publishedLogEntryEvent.ParentLogTransactionId__c);
    System.Assert.areEqual(originStackTraceAttribute.value.stringValue, publishedLogEntryEvent.StackTrace__c);
    Datetime expectedTimestamp = Datetime.newInstance(Long.valueOf(otelLogEntry.timeUnixNano) / 1000000);
    System.Assert.areEqual(expectedTimestamp, publishedLogEntryEvent.Timestamp__c);
  }
}
