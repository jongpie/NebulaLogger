//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description REST Resource class for external integrations to interact with Nebula Logger
 */

@RestResource(urlMapping='/logger/*')
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class LoggerRestResource {
  @TestVisible
  private static final String REQUEST_URI_BASE = '/logger';
  @TestVisible
  private static final Integer STATUS_CODE_200_OK = 200;
  @TestVisible
  private static final Integer STATUS_CODE_201_CREATED = 201;
  @TestVisible
  private static final Integer STATUS_CODE_400_BAD_REQUEST = 400;
  @TestVisible
  private static final Integer STATUS_CODE_401_NOT_AUTHORIZED = 401;
  @TestVisible
  private static final Integer STATUS_CODE_404_NOT_FOUND = 404;
  @TestVisible
  private static final Integer STATUS_CODE_405_METHOD_NOT_ALLOWED = 405;
  private static final Boolean SUPPRESS_NULLS_IN_JSON_SERIALIZATION = true;

  /**
   * @description Processes any HTTP POST requests sent
   */
  @HttpPost
  global static void handlePost() {
    // TODO wrap everything in a try-catch block
    // EndpointRequest endpointRequest = new EndpointRequest(System.RestContext.request);
    // Endpoint endpoint = getEndpoint(endpointRequest.name);

    // EndpointResponse endpointResponse = endpoint.handlePost(endpointRequest);
    // System.RestContext.response = endpointResponse.getRestResponse();
    EndpointRequest endpointRequest = new EndpointRequest(System.RestContext.request);
    Endpoint endpointHandler = LoggerRestResource.getEndpointHandler(endpointRequest);
    EndpointResponse endpointResponse = endpointHandler.handlePost(endpointRequest);

    logErrors(endpointRequest, endpointResponse);
  }

  private static Endpoint getEndpointHandler(EndpointRequest endpointRequest) {
    switch on endpointRequest.name {
      when 'logs' {
        return new LogsEndpoint();
      }
      when else {
        return new UnknownEndpointResponder();
      }
    }
  }

  // TODO revisit - this is probably too many parameters...?
  @SuppressWarnings('PMD.ExcessiveParameterList')
  private static void logErrors(EndpointRequest endpointRequest, EndpointResponse endpointResponse) {
    if (endpointResponse.isSuccess) {
      return;
    }

    LogMessage warningMessage = new LogMessage(
      'Inbound call to {0} endpoint failed with {1} errors:\n\n{2}',
      REQUEST_URI_BASE + '/' + endpointRequest.name,
      endpointResponse.errors.size(),
      System.JSON.serializePretty(endpointResponse.errors)
    );
    Logger.warn(warningMessage).setRestRequestDetails(endpointRequest.restRequest).setRestResponseDetails(endpointResponse.getRestResponse());
    Logger.saveLog();
  }

  /* Base classes that act as the building blocks for all endpoints */
  private abstract class Endpoint {
    public abstract EndpointResponse handlePost(EndpointRequest endpointRequest);
  }

  // Deprecated??
  @TestVisible
  private class EndpointRequest {
    public final String name;
    public final String particle;

    private final System.RestRequest restRequest;

    public EndpointRequest(System.RestRequest restRequest) {
      this.restRequest = restRequest;

      String parsedEndpointName = this.getEndpointName(restRequest.requestUri);

      this.name = parsedEndpointName;
      this.particle = this.getEndpointParticle(restRequest.requestUri, parsedEndpointName);
    }

    public System.RestRequest getRestRequest() {
      return this.restRequest;
    }

    private String getEndpointName(String restRequestUri) {
      // FIXME the comments below are no longer accurate - endpoints like /logs/<some-uuid> are now used
      /*
        Endpoint names will (at least for now) only have one layer, using formats like:
        /logger/logs
        /logger/logs/?some-url-parameter=true&and-another=true
        /logger/something
        /logger/something?another-url-parameter=something
        /Nebula/logger/logs
        /Nebula/logger/logs/?some-url-parameter=true&and-another=true
        /Nebula/logger/something
        /Nebula/logger/something?another-url-parameter=something

        The endpoint name will be just the last bit of the URL, without any parameters or '/' slashes.
        So if the URL is:
            /logger/something?some-url-parameter=true&and-another=true
        then the endpoint name will be 'something'
      */

      String parsedEndpointName = restRequestUri.substringAfter(REQUEST_URI_BASE);
      if (parsedEndpointName.contains('?')) {
        parsedEndpointName = parsedEndpointName.substringBefore('?');
      }
      parsedEndpointName = parsedEndpointName.removeStart('/').removeEnd('/');
      if (parsedEndpointName.contains('/')) {
        parsedEndpointName = parsedEndpointName.substringBefore('/');
      }
      return String.isNotBlank(parsedEndpointName) ? parsedEndpointName : null;
    }

    private String getEndpointParticle(String restRequestUri, String endpointName) {
      String parsedEndpointParticle = restRequestUri.substringAfter('/' + endpointName + '/');
      if (parsedEndpointParticle?.contains('?')) {
        parsedEndpointParticle = parsedEndpointParticle.substringBefore('?');
      }
      parsedEndpointParticle = parsedEndpointParticle.removeEnd('/');

      return String.isBlank(parsedEndpointParticle) ? null : parsedEndpointParticle;
    }
  }

  @TestVisible
  private class EndpointResponse {
    public final List<EndpointError> errors = new List<EndpointError>();

    // The status code doesn't need to be returned in the RestResponse body
    // since the RestResponse headers will include the status code, so use
    // 'transient' to exclude it during serialization
    public transient Integer statusCode;

    public Boolean isSuccess {
      get {
        return this.errors.isEmpty();
      }
    }

    public EndpointResponse addError(System.Exception apexException) {
      return this.addError(new EndpointError(apexException));
    }

    public EndpointResponse addError(EndpointError endpointError) {
      this.errors.add(endpointError);
      return this;
    }

    public EndpointResponse setStatusCode(Integer statusCode) {
      this.statusCode = statusCode;
      return this;
    }

    public System.RestResponse getRestResponse() {
      System.RestResponse restResponse = System.RestContext.response ?? new System.RestResponse();
      restResponse.addHeader('Content-Type', 'application/json');
      restResponse.responseBody = Blob.valueOf(System.JSON.serialize(this, SUPPRESS_NULLS_IN_JSON_SERIALIZATION));
      restResponse.statusCode = this.statusCode;
      return restResponse;
    }
  }

  @TestVisible
  private virtual class EndpointError {
    public final String message;
    public final String type;

    public EndpointError(System.Exception apexException) {
      this(apexException.getMessage(), apexException.getTypeName());
    }

    public EndpointError(String message) {
      this(message, null);
    }

    public EndpointError(String message, String type) {
      this.message = message;
      this.type = type;
    }
  }

  /* Endpoint implementations */
  private class LogsEndpoint extends Endpoint {
    public override EndpointResponse handlePost(EndpointRequest endpointRequest) {
      EndpointResponse postResponse = new EndpointResponse();
      try {
        this.validateHttpHeaders(endpointRequest.getRestRequest().headers);

        LoggerOTelSchema.LogsPayload logsPayload = this.deserializeLogsPayload(endpointRequest);

        String saveMethodName = endpointRequest.getRestRequest().headers.get('X-NebulaLogger-SaveMethod');

        // TODO revist LoggerAttribute__c object (which would only be used when saveMethod == 'SYNCHRONOUS_DML').
        // There should also be a LoggerParameter__mdt record to control the default (true by default, I think).
        String storeUnmappedAttributes = endpointRequest.getRestRequest().headers.get('X-NebulaLogger-StoreUnmappedAttributes');

        this.saveLog(logsPayload, saveMethodName);

        return postResponse.setStatusCode(STATUS_CODE_201_CREATED);
      } catch (Exception apexException) {
        return postResponse.setStatusCode(STATUS_CODE_400_BAD_REQUEST).addError(apexException);
      }
    }

    private void validateHttpHeaders(Map<String, String> headers) {
      // TODO
      if (headers == null) {
        return;
      }

      String contentTypeHeader = headers.get('Content-Type')?.trim();
      if (String.isNotBlank(contentTypeHeader) && contentTypeHeader != 'application/json') {
        throw new System.IllegalArgumentException('Only \'application/json\' is supported for Content-Type, received: ' + headers.get('Content-Type'));
      }
    }

    private void saveLog(LoggerOTelSchema.LogsPayload logsPayload, String saveMethodName) {
      switch on saveMethodName?.toUpperCase() {
        when 'EVENT_BUS' {
          List<LogEntryEvent__e> convertedLogEntryEvents = LoggerOTelAdapter.convertToPlatformEvents(logsPayload);
          LoggerDataStore.getEventBus().publishRecords(convertedLogEntryEvents);
        }
        when 'SYNCHRONOUS_DML' {
          // TODO finalize how this should work for upserting records, etc.
          Map<Schema.SObjectType, List<SObject>> sobjectTypeToConvertedRecords = LoggerOTelAdapter.convertToCustomObjects(logsPayload);
          // LoggerDataStore.getEventBus().publishRecords(convertedLogEntryEvents);
        }
        // TODO revisit this
        when else {
          List<LogEntryEvent__e> convertedLogEntryEvents = LoggerOTelAdapter.convertToPlatformEvents(logsPayload);
          LoggerDataStore.getEventBus().publishRecords(convertedLogEntryEvents);
        }
      }
    }

    private LoggerOTelSchema.LogsPayload deserializeLogsPayload(EndpointRequest endpointRequest) {
      String jsonBody = endpointRequest.restRequest.requestBody?.toString();

      if (String.isBlank(jsonBody)) {
        throw new System.IllegalArgumentException('No data provided');
      }

      return (LoggerOTelSchema.LogsPayload) System.JSON.deserialize(jsonBody, LoggerOTelSchema.LogsPayload.class);
    }
  }

  private class UnknownEndpointResponder extends Endpoint {
    public override EndpointResponse handlePost(EndpointRequest endpointRequest) {
      String errorMessage = 'Calling root endpoint /logger is not supported, please provide a specific endpoint';
      if (endpointRequest.name != null) {
        errorMessage = 'Unknown endpoint provided: ' + endpointRequest.name;
      }
      return new EndpointResponse().setStatusCode(STATUS_CODE_404_NOT_FOUND).addError(new EndpointError(errorMessage));
    }
  }
}
