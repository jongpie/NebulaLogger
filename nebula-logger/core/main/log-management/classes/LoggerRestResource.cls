//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/**
 * @group Log Management
 * @description REST Resource class for external integrations to create & retrieve logging data
 */

@RestResource(urlMapping='/logger/*')
@SuppressWarnings('PMD.AvoidDebugStatements, PMD.AvoidGlobalModifier')
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
    public abstract EndpointResponse handlePost(EndpointRequest endpointRequest);
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
        OTelLogsPayload logsPayload = this.deserializeLog(endpointRequest.body);
        this.saveLog(logsPayload);
        postResponse.setStatusCode(STATUS_CODE_201_CREATED);
        return postResponse;
      } catch (Exception apexException) {
        postResponse.setStatusCode(STATUS_CODE_400_BAD_REQUEST).addError(apexException);
        return postResponse;
      }
    }
    private void saveLog(OTelLogsPayload logsPayload) {
      LoggerDataStore.getEventBus().publishRecords(logsPayload.getConvertedLogEntryEvents());
    }

    private OTelLogsPayload deserializeLog(String jsonBody) {
      if (String.isBlank(jsonBody)) {
        throw new System.IllegalArgumentException('No data provided');
      }

      OTelLogsPayload logPayload = (OTelLogsPayload) System.JSON.deserialize(jsonBody, OTelLogsPayload.class);

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
    public override EndpointResponse handlePost(EndpointRequest endpointRequest) {
      return this.handleResponse(endpointRequest);
    }

    private EndpointResponse handleResponse(EndpointRequest endpointRequest) {
      String errorMessage = 'Calling root endpoint /logger is not supported, please provide a specific endpoint';
      if (endpointRequest.name != null) {
        errorMessage = 'Unknown endpoint provided: ' + endpointRequest.name;
      }
      return new EndpointResponse().setStatusCode(STATUS_CODE_404_NOT_FOUND).addError(new EndpointError(errorMessage));
    }
  }

  // OpenTelemetry classes - these correspond to OTel v1.36.0's HTTP JSON format for the logs data model
  // https://opentelemetry.io/docs/specs/otel/logs/data-model/
  // https://opentelemetry.io/docs/specs/otel/protocol/file-exporter/#examples
  // https://github.com/open-telemetry/opentelemetry-proto/blob/main/examples/logs.json
  public class OTelLogsPayload {
    public final List<OTelResourceLog> resourceLogs = new List<OTelResourceLog>();

    public List<LogEntryEvent__e> getConvertedLogEntryEvents() {
      List<LogEntryEvent__e> logEntryEvents = new List<LogEntryEvent__e>();

      for (OTelResourceLog resourceLog : this.resourceLogs) {
        logEntryEvents.addAll(resourceLog.getLogEntryEvents());
      }

      return logEntryEvents;
    }
  }

  public class OTelResourceLog {
    public final OTelResource resource = new OTelResource();
    public final List<OTelScopeLog> scopeLogs = new List<OTelScopeLog>();

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

  // OTel supports additional types boolValue, float64Value, and intValue
  // but there's not currently a need for them in Nebula Logger's data model
  // As more mappings are added, these types will be re-added when needed
  public class OTelAttribute {
    public final String key;
    public final OTelAttributeValue value;

    // public OTelAttribute(String key, Boolean value) {
    //   this.key = key;
    //   this.value = new OTelAttributeValue(value);
    // }

    // public OTelAttribute(String key, Decimal value) {
    //   this.key = key;
    //   this.value = new OTelAttributeValue(value);
    // }

    // public OTelAttribute(String key, Integer value) {
    //   this.key = key;
    //   this.value = new OTelAttributeValue(value);
    // }

    public OTelAttribute(String key, String value) {
      this.key = key;
      this.value = new OTelAttributeValue(value);
    }
  }

  public class OTelAttributeValue {
    // public final Boolean boolValue;
    // public final Decimal float64Value;
    // public final Integer intValue;
    public final String stringValue;

    // public OTelAttributeValue(Boolean value) {
    //   this.boolValue = value;
    // }

    // public OTelAttributeValue(Decimal value) {
    //   this.float64Value = value;
    // }

    // public OTelAttributeValue(Integer value) {
    //   this.intValue = value;
    // }

    public OTelAttributeValue(String value) {
      this.stringValue = value;
    }
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
          // TODO
          // when 'service.version' {
          // }
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
    public List<OTelAttribute> attributes = new List<OTelAttribute>();
    public OTelAttributeValue body;
    public String severityText;
    public String timeUnixNano = (System.now().getTime() * 1000000).toString();
    // TODO revisit mappings for spanId and traceId
    // public String spanId;
    // public String traceId;

    private transient LogEntryEvent__e convertedLogEntryEvent;

    public LogEntryEvent__e getLogEntryEvent() {
      if (this.convertedLogEntryEvent == null) {
        System.LoggingLevel entryLoggingLevel = this.getLoggingLevel();
        Long entryEpochTimestamp = Long.valueOf(this.timeUnixNano) / 1000000;
        Datetime entryTimestamp = Datetime.newInstance(entryEpochTimestamp);

        this.convertedLogEntryEvent = Logger.newEntry(entryLoggingLevel, this.body?.stringValue).setTimestamp(entryTimestamp).getLogEntryEvent();
        this.convertedLogEntryEvent.LimitsAggregateQueriesMax__c = null;
        this.convertedLogEntryEvent.LimitsAsyncCallsMax__c = null;
        this.convertedLogEntryEvent.LimitsCalloutsMax__c = null;
        this.convertedLogEntryEvent.LimitsCpuTimeMax__c = null;
        this.convertedLogEntryEvent.LimitsDmlRowsMax__c = null;
        this.convertedLogEntryEvent.LimitsDmlStatementsMax__c = null;
        this.convertedLogEntryEvent.LimitsEmailInvocationsMax__c = null;
        this.convertedLogEntryEvent.LimitsFutureCallsMax__c = null;
        this.convertedLogEntryEvent.LimitsHeapSizeMax__c = null;
        this.convertedLogEntryEvent.LimitsMobilePushApexCallsMax__c = null;
        this.convertedLogEntryEvent.LimitsPublishImmediateDmlStatementsMax__c = null;
        this.convertedLogEntryEvent.LimitsQueueableJobsMax__c = null;
        this.convertedLogEntryEvent.LimitsSoqlQueriesMax__c = null;
        this.convertedLogEntryEvent.LimitsSoqlQueryLocatorRowsMax__c = null;
        this.convertedLogEntryEvent.LimitsSoqlQueryRowsMax__c = null;
        this.convertedLogEntryEvent.LimitsSoslSearchesMax__c = null;
        this.convertedLogEntryEvent.LimitsAggregateQueriesUsed__c = null;
        this.convertedLogEntryEvent.LimitsAsyncCallsUsed__c = null;
        this.convertedLogEntryEvent.LimitsCalloutsUsed__c = null;
        this.convertedLogEntryEvent.LimitsCpuTimeUsed__c = null;
        this.convertedLogEntryEvent.LimitsDmlRowsUsed__c = null;
        this.convertedLogEntryEvent.LimitsDmlStatementsUsed__c = null;
        this.convertedLogEntryEvent.LimitsEmailInvocationsUsed__c = null;
        this.convertedLogEntryEvent.LimitsFutureCallsUsed__c = null;
        this.convertedLogEntryEvent.LimitsMobilePushApexCallsUsed__c = null;
        this.convertedLogEntryEvent.LimitsQueueableJobsUsed__c = null;
        this.convertedLogEntryEvent.LimitsPublishImmediateDmlStatementsUsed__c = null;
        this.convertedLogEntryEvent.LimitsSoqlQueriesUsed__c = null;
        this.convertedLogEntryEvent.LimitsSoqlQueryLocatorRowsUsed__c = null;
        this.convertedLogEntryEvent.LimitsSoqlQueryRowsUsed__c = null;
        this.convertedLogEntryEvent.LimitsSoslSearchesUsed__c = null;
        this.convertedLogEntryEvent.LimitsHeapSizeUsed__c = null;
        this.convertedLogEntryEvent.OriginLocation__c = null;
        this.convertedLogEntryEvent.OriginSourceActionName__c = null;
        this.convertedLogEntryEvent.OriginSourceApiName__c = null;
        this.convertedLogEntryEvent.OriginSourceId__c = null;
        this.convertedLogEntryEvent.OriginSourceMetadataType__c = null;
        this.convertedLogEntryEvent.OriginType__c = 'API';
        this.convertedLogEntryEvent.StackTrace__c = null;

        Map<Schema.SObjectField, Object> supplementalFieldToValue = this.convertAttributes();
        for (Schema.SObjectField field : supplementalFieldToValue.keySet()) {
          this.convertedLogEntryEvent.put(field, supplementalFieldToValue.get(field));
        }
      }

      return this.convertedLogEntryEvent;
    }

    private System.LoggingLevel getLoggingLevel() {
      switch on this.severityText?.toUpperCase() {
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
          // Use DEBUG as a fallback value, similar to how it's done in Logger
          System.debug(System.LoggingLevel.DEBUG, 'Unable to convert severity text to logging level: ' + this.severityText);
          return System.LoggingLevel.DEBUG;
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
          when 'exception.stack_trace' {
            supplementalFieldToValue.put(LogEntryEvent__e.ExceptionStackTrace__c, entryAttribute.value?.stringValue);
          }
          when 'exception.type' {
            supplementalFieldToValue.put(LogEntryEvent__e.ExceptionType__c, entryAttribute.value?.stringValue);
          }
          when 'origin.stack_trace' {
            supplementalFieldToValue.put(LogEntryEvent__e.StackTrace__c, entryAttribute.value?.stringValue);
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
