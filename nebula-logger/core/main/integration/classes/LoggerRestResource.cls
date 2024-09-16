//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Integration
 * @description REST Resource class for external integrations to create & retrieve logging data
 */

@RestResource(urlMapping='/logger/*')
@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class LoggerRestResource {
  // TODO revisit REQUEST_URI_BASE value / add tests to make it work with a namespace
  /*
    From the Apex Dev docs (https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_annotation_rest_resource.htm):
      "The URL for a namespaced class contains the namespace. For example, if your class is in namespace abc and the class is
       mapped to your_url, then the API URL is modified as follows: https://instance.salesforce.com/services/apexrest/abc/your_url/.
       In the case of a URL collision, the namespaced class is always used."
    */
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

  @HttpPost
  global static void handlePost() {
    // TODO wrap everything in a try-catch block
    EndpointRequest endpointRequest = new EndpointRequest(System.RestContext.request);
    Endpoint endpoint = getEndpoint(endpointRequest.name);

    EndpointResponse endpointResponse = endpoint.handlePost(endpointRequest);
    System.RestContext.response = buildRestResponse(endpointResponse);

    logErrors(endpointRequest, endpointResponse, System.RestContext.request, System.RestContext.response);
  }

  private static Endpoint getEndpoint(String endpointName) {
    switch on endpointName {
      when 'logs' {
        return new LogsEndpoint();
      }
      when else {
        return new UnknownEndpointResponder();
      }
    }
  }

  private static System.RestResponse buildRestResponse(EndpointResponse endpointResponse) {
    System.RestResponse restResponse = System.RestContext.response ?? new System.RestResponse();
    restResponse.addHeader('Content-Type', 'application/json');
    restResponse.responseBody = Blob.valueOf(System.JSON.serialize(endpointResponse, SUPPRESS_NULLS_IN_JSON_SERIALIZATION));
    restResponse.statusCode = endpointResponse.statusCode;
    return restResponse;
  }

  // TODO revisit - this is probably too many parameters...?
  private static void logErrors(
    EndpointRequest endpointRequest,
    EndpointResponse endpointResponse,
    System.RestRequest restRequest,
    System.RestResponse restResponse
  ) {
    if (endpointResponse.isSuccess) {
      return;
    }

    LogMessage warningMessage = new LogMessage(
      'Inbound call to {0} endpoint failed with {1} errors:\n\n{2}',
      REQUEST_URI_BASE + '/' + endpointRequest.name,
      endpointResponse.errors.size(),
      System.JSON.serializePretty(endpointResponse.errors)
    );
    Logger.warn(warningMessage).setRestRequestDetails(restRequest).setRestResponseDetails(restResponse);
    Logger.saveLog();
  }

  /* Base classes that act as the building blocks for all endpoints */
  private abstract class Endpoint {
    // For now, only is used by Nebula Logger, so there's no need to have methods
    // for the other HTTP verbs DELETE, PATCH, and PUT.
    public virtual EndpointResponse handleGet(EndpointRequest endpointRequest) {
      return this.getDefaultResponse(endpointRequest, 'GET');
    }

    public virtual EndpointResponse handlePost(EndpointRequest endpointRequest) {
      return this.getDefaultResponse(endpointRequest, 'POST');
    }

    private EndpointResponse getDefaultResponse(EndpointRequest endpointRequest, String httpMethod) {
      System.Exception unsupportedOperationException = new System.IllegalArgumentException(
        REQUEST_URI_BASE + '/' + endpointRequest.name + ' endpoint does not support ' + httpMethod + ' requests'
      );
      return new EndpointResponse(endpointRequest).setStatusCode(STATUS_CODE_405_METHOD_NOT_ALLOWED).addError(unsupportedOperationException);
    }
  }

  @TestVisible
  private class EndpointRequest {
    public String body;
    // public EndpointRequestContext context;
    public List<String> headerKeys;
    public String httpMethod;
    public String name;
    public Map<String, String> parameters;
    public String particle;
    public String uri;

    public EndpointRequest(System.RestRequest restRequest) {
      String parsedName = this.getEndpointName(restRequest.requestUri);
      String requestBody = restRequest.requestBody?.toString();

      this.body = String.isBlank(requestBody) ? null : requestBody;
      this.headerKeys = new List<String>(restRequest.headers.keySet());
      this.httpMethod = restRequest.httpMethod;
      this.name = parsedName;
      this.parameters = restRequest.params;
      this.particle = this.getEndpointParticle(restRequest.requestUri, parsedName);
      this.uri = restRequest.requestUri;
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
      if (String.isBlank(parsedEndpointName)) {
        parsedEndpointName = null;
      }
      return parsedEndpointName;
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
    public final EndpointRequest endpointRequest;
    // public final EndpointRequestContext endpointRequestContext;
    public final List<EndpointError> errors = new List<EndpointError>();
    // public final EndpointLoggerContext logger;
    // public final EndpointOrganizationContext organization;
    // public final EndpointUserContext user;

    // The status code doesn't need to be returned in the RestResponse body
    // since the RestResponse headers will include the status code, so use
    // 'transient' to exclude it during serialization
    public transient Integer statusCode;

    public Boolean isSuccess {
      get {
        return this.errors.isEmpty();
      }
    }

    public EndpointResponse(EndpointRequest endpointRequest) {
      if (this.isTruthy(endpointRequest.parameters, 'verbose')) {
        // TODO revisit to decide if/what endpoint info should be returned in the reponse
        this.endpointRequest = endpointRequest;
        // this.endpointRequest.context = new EndpointRequestContext();
        // this.logger = new EndpointLoggerContext();
        // this.organization = new EndpointOrganizationContext();
        // this.user = new EndpointUserContext();
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

    private Boolean isTruthy(Map<String, String> parameters, String targetParameterName) {
      /*
                If 'some-parameter' is not in the map of parameters, it will be interpreted as false.
                All of these example URL parameters should return true for 'some-parameter':
                    - /services/apexrest/logger/some-endpoint?some-parameter
                    - /services/apexrest/logger/some-endpoint?some-parameter=true
                    - /services/apexrest/logger/some-endpoint?some-parameter=TRUE
                    - /services/apexrest/logger/some-endpoint?some-parameter=True
                    - /services/apexrest/logger/some-endpoint?some-parameter=1
                Any other provided value will be interpreted as false for 'some-parameter'.
                    - /services/apexrest/logger/some-endpoint?some-parameter=false
                    - /services/apexrest/logger/some-endpoint?some-parameter=FALSE
                    - /services/apexrest/logger/some-endpoint?some-parameter=False
                    - /services/apexrest/logger/some-endpoint?some-parameter=0
                    - /services/apexrest/logger/some-endpoint?some-parameter=anything-else
            */
      String parameterStringValue = parameters.get(targetParameterName);
      return (parameters.containsKey(targetParameterName) && String.isBlank(parameterStringValue)) ||
        parameterStringValue?.toLowerCase() == 'true' ||
        parameterStringValue == '1';
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

  /* Endpoints */
  private class LogsEndpoint extends Endpoint {
    // public override EndpointResponse handleGet(EndpointRequest endpointRequest) {
    //   String possibleTransactionId = endpointRequest.particle;
    //   if (possibleTransactionId != null) {
    //     return this.queryLog(endpointRequest);
    //   } else {
    //     return this.searchLogs(endpointRequest);
    //   }
    // }

    public override EndpointResponse handlePost(EndpointRequest endpointRequest) {
      EndpointResponse postResponse = new EndpointResponse(endpointRequest);
      try {
        // LogDTO logToCreate = this.deserializeLog(endpointRequest.body);
        OpenTelemetryLogPayload logsPayload = this.deserializeLog(endpointRequest.body);
        // this.saveLog(logToCreate);
        postResponse.setStatusCode(STATUS_CODE_201_CREATED);
        return postResponse;
      } catch (Exception apexException) {
        postResponse.setStatusCode(STATUS_CODE_400_BAD_REQUEST).addError(apexException);
        return postResponse;
      }
    }

    /* private void saveLog(LogDTO logCreateRequest) {
      Logger.setParentLogTransactionId(logCreateRequest.parentLogTransactionId);
      Logger.setScenario(logCreateRequest.transactionScenario);

      for (LogEntryDTO logEntryCreateRequest : logCreateRequest.logEntries) {
        // TODO need to revisit the shape of loggingLevel - should it be a string, or a Map/inner class?
        // For inbound requests to create a log, it's easier for developers to just pass a string
        // For responses, having loggingLevel as a Mapl/inner class might make the JSON more readable...?
        // System.LoggingLevel loggingLevel = Logger.getLoggingLevel(logEntryCreateRequest.loggingLevel.get('name'));
        System.LoggingLevel loggingLevel = Logger.getLoggingLevel(logEntryCreateRequest.loggingLevel);
        Logger.newEntry(loggingLevel, logEntryCreateRequest.message)
          // FIXME The managed package currently doesn't have a way to set the value
          // of OriginType__c = 'Integration'
          .setRecord(logEntryCreateRequest.relatedRecordId)
          // FIXME The managed package currently doesn't have the .setTimestamp() builder method,
          // so there's not a great way to correctly set the Timestamp__c field yet
          // .setTimestamp(logEntryCreateRequest.timestamp)
          .addTags(logEntryCreateRequest.tags);
      }

      Logger.saveLog();
    } */

    // private LogDTO deserializeLog(String jsonBody) {
    //   if (String.isBlank(jsonBody)) {
    //     throw new System.IllegalArgumentException('No data provided');
    //   }

    //   LogDTO logToCreate = (LogDTO) System.JSON.deserialize(jsonBody, LogDTO.class);

    //   // TODO add support for adding these as errors in logToCreate.errors
    //   // (instead of only bubbling up 1 via throwing an exception)
    //   if (String.isBlank(logToCreate.originSystemName)) {
    //     throw new System.IllegalArgumentException('No data provided for required property "originSystemName"');
    //   }

    //   if (logToCreate.logEntries == null || logToCreate.logEntries.isEmpty()) {
    //     throw new System.IllegalArgumentException('No data provided for required property "logEntries"');
    //   }

    //   return logToCreate;
    // }
    private OpenTelemetryLogPayload deserializeLog(String jsonBody) {
      if (String.isBlank(jsonBody)) {
        throw new System.IllegalArgumentException('No data provided');
      }

      OpenTelemetryLogPayload logPayload = (OpenTelemetryLogPayload) System.JSON.deserialize(jsonBody, OpenTelemetryLogPayload.class);

      // TODO add support for adding these as errors in logToCreate.errors
      // (instead of only bubbling up 1 via throwing an exception)
      // if (String.isBlank(logToCreate.originSystemName)) {
      // if (String.isBlank(logPayload.resourceLogs)) {
      //   throw new System.IllegalArgumentException('No data provided for required property "originSystemName"');
      // }

      // if (logToCreate.logEntries == null || logToCreate.logEntries.isEmpty()) {
      //   throw new System.IllegalArgumentException('No data provided for required property "logEntries"');
      // }

      return logPayload;
    }
  }

  private class UnknownEndpointResponder extends Endpoint {
    public override EndpointResponse handleGet(EndpointRequest endpointRequest) {
      return this.handleResponse(endpointRequest);
    }

    public override EndpointResponse handlePost(EndpointRequest endpointRequest) {
      return this.handleResponse(endpointRequest);
    }

    private EndpointResponse handleResponse(EndpointRequest endpointRequest) {
      String errorMessage;
      if (endpointRequest.name == null) {
        errorMessage = 'Calling root endpoint /logger is not supported, please provide a specific endpoint';
      } else {
        errorMessage = 'Unknown endpoint provided: ' + endpointRequest.uri;
      }
      return new EndpointResponse(endpointRequest).setStatusCode(STATUS_CODE_404_NOT_FOUND).addError(new EndpointError(errorMessage));
    }
  }

  // OpenTelemetry classes - these correspond to OTel v1.36.0's HTTP JSON format for the logs data model
  // https://opentelemetry.io/docs/specs/otel/logs/data-model/
  // https://opentelemetry.io/docs/specs/otel/protocol/file-exporter/#examples
  // https://github.com/open-telemetry/opentelemetry-proto/blob/main/examples/logs.json
  public class OpenTelemetryLogPayload {
    public List<ResourceLog> resourceLogs = new List<ResourceLog>();

    public List<LogEntryEvent__e> getLogEntryEvents() {
      List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();

      for (ResourceLog resourceLog : this.resourceLogs) {
        logEntryEvents.addAll(resourceLog.getLogEntryEvents());
      }

      return logEntryEvents;
    }
  }

  public class ResourceLog {
    public OTelResource resource = new OTelResource();
    public List<OTelScopeLog> scopeLogs = new List<OTelScopeLog>();

    public List<LogEntryEvent__e> getLogEntryEvents() {
      List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();

      for (OTelScopeLog scopeLog : this.scopeLogs) {
        for (OTelLogRecord otelLogEntry : scopeLog.logRecords) {
          LogEntryEvent__e convertedLogEntryEvent = otelLogEntry.getLogEntryEvent();
          Map<Schema.SObjectField, Object> supplementalFieldToValue = this.resource.convertAttributes();
          for (Schema.SObjectField field : supplementalFieldToValue.keySet()) {
            convertedLogEntryEvent.put(field, supplementalFieldToValue.get(field));
          }
          logEntryEvents.add(convertedLogEntryEvent);
        }
      }

      return logEntryEvents;
    }
  }

  public class OTelAttribute {
    public String key;
    public OTelAttributeValue value = new OTelAttributeValue();
  }

  public class OTelAttributeValue {
    public Boolean boolValue;
    public Decimal float64Value;
    public Integer intValue;
    public String stringValue;
  }

  public class OTelResource {
    public List<OTelAttribute> attributes = new List<OTelAttribute>();

    private Map<Schema.SObjectField, Object> convertAttributes() {
      Map<Schema.SObjectField, Object> supplementalFieldToValue = new Map<Schema.SObjectField, Object>();

      for (OTelAttribute entryAttribute : this.attributes) {
        switch on entryAttribute.key {
          when 'service.name' {
            supplementalFieldToValue.put(LogEntryEvent__e.OriginSystemName__c, entryAttribute.value?.stringValue);
          }
          when 'service.version' {
            // TODO
          }
        }
      }

      return supplementalFieldToValue;
    }
  }

  public class OTelScope {
    public String name;
    public String version;
  }

  public class OTelScopeLog {
    public OTelScope scope;
    public List<OTelLogRecord> logRecords = new List<OTelLogRecord>();
  }

  public class OTelLogRecord {
    public String timeUnixNano;
    public String severityText;
    public OTelAttributeValue body;
    public List<OTelAttribute> attributes = new List<OTelAttribute>();
    // TODO revisit mappings for traceId and spanId
    // public String traceId;
    // public String spanId;

    private transient LogEntryEvent__e convertedLogEntryEvent;

    public LogEntryEvent__e getLogEntryEvent() {
      if (this.convertedLogEntryEvent == null) {
        System.LoggingLevel entryLoggingLevel = this.getLoggingLevel();
        Long entryEpochTimestamp = Long.valueOf(this.timeUnixNano) / 1000;

        this.convertedLogEntryEvent = new LogEntryEvent__e(
          EpochTimestamp__c = entryEpochTimestamp,
          LoggingLevel__c = entryLoggingLevel.name(),
          LoggingLevelOrdinal__c = entryLoggingLevel.ordinal(),
          Message__c = this.body?.stringValue,
          Timestamp__c = Datetime.newInstance(entryEpochTimestamp),
          TimestampString__c = '' + entryEpochTimestamp
        );
        Map<Schema.SObjectField, Object> supplementalFieldToValue = this.convertAttributes();
        for (Schema.SObjectField field : supplementalFieldToValue.keySet()) {
          this.convertedLogEntryEvent.put(field, supplementalFieldToValue.get(field));
        }
      }

      return this.convertedLogEntryEvent;
    }

    private System.LoggingLevel getLoggingLevel() {
      switch on this.severityText {
        when 'ERROR' {
          return System.LoggingLevel.ERROR;
        }
        when 'WARN' {
          return System.LoggingLevel.WARN;
        }
        when 'INFO' {
          return System.LoggingLevel.INFO;
        }
        when 'DEBUG' {
          return System.LoggingLevel.DEBUG;
        }
        when 'TRACE3' {
          return System.LoggingLevel.FINE;
        }
        when 'TRACE2' {
          return System.LoggingLevel.FINER;
        }
        when 'TRACE' {
          return System.LoggingLevel.FINEST;
        }
        when else {
          return null;
        }
      }
    }

    private Map<Schema.SObjectField, Object> convertAttributes() {
      Map<Schema.SObjectField, Object> supplementalFieldToValue = new Map<Schema.SObjectField, Object>();

      for (OTelAttribute entryAttribute : this.attributes) {
        switch on entryAttribute.key {
          when 'exception.message' {
            supplementalFieldToValue.put(LogEntryEvent__e.ExceptionMessage__c, entryAttribute.value?.stringValue);
          }
          when 'exception.type' {
            supplementalFieldToValue.put(LogEntryEvent__e.ExceptionType__c, entryAttribute.value?.stringValue);
          }
          when 'http_request.body' {
            supplementalFieldToValue.put(LogEntryEvent__e.HttpRequestBody__c, entryAttribute.value?.stringValue);
          }
          when 'http_request.body_masked' {
            supplementalFieldToValue.put(LogEntryEvent__e.HttpRequestBodyMasked__c, entryAttribute.value?.stringValue);
          }
          when 'http_request.compressed' {
            supplementalFieldToValue.put(LogEntryEvent__e.HttpRequestCompressed__c, entryAttribute.value?.stringValue);
          }
          when 'http_request.endpoint' {
            supplementalFieldToValue.put(LogEntryEvent__e.HttpRequestEndpoint__c, entryAttribute.value?.stringValue);
          }
          when 'http_request.header_keys' {
            supplementalFieldToValue.put(LogEntryEvent__e.HttpRequestHeaderKeys__c, entryAttribute.value?.stringValue);
          }
          when 'http_request.headers' {
            supplementalFieldToValue.put(LogEntryEvent__e.HttpRequestHeaders__c, entryAttribute.value?.stringValue);
          }
          when 'http_request.method' {
            supplementalFieldToValue.put(LogEntryEvent__e.HttpRequestMethod__c, entryAttribute.value?.stringValue);
          }
          when 'http_response.body' {
            supplementalFieldToValue.put(LogEntryEvent__e.HttpResponseBody__c, entryAttribute.value?.stringValue);
          }
          when 'http_response.body_masked' {
            supplementalFieldToValue.put(LogEntryEvent__e.HttpResponseBodyMasked__c, entryAttribute.value?.stringValue);
          }
          when 'http_response.header_keys' {
            supplementalFieldToValue.put(LogEntryEvent__e.HttpResponseHeaderKeys__c, entryAttribute.value?.stringValue);
          }
          when 'http_response.headers' {
            supplementalFieldToValue.put(LogEntryEvent__e.HttpResponseHeaders__c, entryAttribute.value?.stringValue);
          }
          when 'http_response.status' {
            supplementalFieldToValue.put(LogEntryEvent__e.HttpResponseStatus__c, entryAttribute.value?.stringValue);
          }
          when 'http_response.status_code' {
            supplementalFieldToValue.put(LogEntryEvent__e.HttpResponseStatusCode__c, entryAttribute.value?.stringValue);
          }
          when 'logged_by.username' {
            supplementalFieldToValue.put(LogEntryEvent__e.LoggedByUsername__c, entryAttribute.value?.stringValue);
          }
          when 'parent_log.transaction_id' {
            supplementalFieldToValue.put(LogEntryEvent__e.ParentLogTransactionId__c, entryAttribute.value?.stringValue);
          }
        }
      }

      return supplementalFieldToValue;
    }
  }

  /*
    {
        "resourceLogs": [
            {
                "resource": {
                    "attributes": [
                        {
                            "key": "resource-attr",
                            "value": { "stringValue": "resource-attr-val-1" }
                        }
                    ]
                },
                "scopeLogs": [
                    {
                        "scope": {},
                        "logRecords": [
                            {
                                "timeUnixNano": "1581452773000000789",
                                "severityNumber": 9,
                                "severityText": "Info",
                                "body": { "stringValue": "This is a log message" },
                                "attributes": [
                                    { "key": "app", "value": { "stringValue": "server" } },
                                    { "key": "instance_num", "value": { "intValue": "1" } }
                                ],
                                "droppedAttributesCount": 1,
                                "traceId": "08040201000000000000000000000000",
                                "spanId": "0102040800000000"
                            },
                            {
                                "timeUnixNano": "1581452773000000789",
                                "severityNumber": 9,
                                "severityText": "Info",
                                "body": { "stringValue": "something happened" },
                                "attributes": [
                                    { "key": "customer", "value": { "stringValue": "acme" } },
                                    { "key": "env", "value": { "stringValue": "dev" } }
                                ],
                                "droppedAttributesCount": 1,
                                "traceId": "",
                                "spanId": ""
                            }
                        ]
                    }
                ]
            }
        ]
    }
    */
}
