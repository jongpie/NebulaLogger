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
global with sharing class LoggerRestResource_Old {
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

  @HttpGet
  global static void handleGet() {
    // TODO wrap everything in a try-catch block?
    EndpointRequest endpointRequest = new EndpointRequest(System.RestContext.request);
    Endpoint endpoint = getEndpoint(endpointRequest.name);

    EndpointResponse endpointResponse = endpoint.handleGet(endpointRequest);
    System.RestContext.response = buildRestResponse(endpointResponse);

    logErrors(endpointRequest, endpointResponse, System.RestContext.request, System.RestContext.response);
  }

  @HttpPost
  global static void handlePost() {
    // TODO wrap everything in a try-catch block?
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
      when 'log-entries' {
        return new LogEntriesEndpoint();
      }
      when 'logger-scenarios' {
        return new LoggerScenariosEndpoint();
      }
      when 'logger-tags' {
        return new LoggerTagsEndpoint();
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

    Nebula.LogMessage warningMessage = new Nebula.LogMessage(
      'Inbound call to {0} endpoint failed with {1} errors:\n\n{2}',
      REQUEST_URI_BASE + '/' + endpointRequest.name,
      endpointResponse.errors.size(),
      System.JSON.serializePretty(endpointResponse.errors)
    );
    Nebula.Logger.warn(warningMessage).setRestRequestDetails(restRequest).setRestResponseDetails(restResponse);
    Nebula.Logger.saveLog();
  }

  /* Base classes that act as the building blocks for all endpoints */
  private abstract class Endpoint {
    // For now, only GET & POST are used by Nebula Logger, so there's no need to have methods
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
    public EndpointRequestContext context;
    public List<String> headerKeys;
    public String name;
    public Map<String, String> parameters;
    public String particle;
    public String uri;

    public EndpointRequest(System.RestRequest restRequest) {
      String parsedName = this.getEndpointName(restRequest.requestUri);
      String requestBody = restRequest.requestBody?.toString();

      this.body = String.isBlank(requestBody) ? null : requestBody;
      this.headerKeys = new List<String>(restRequest.headers.keySet());
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
    public final EndpointRequestContext endpointRequestContext;
    public final List<EndpointError> errors = new List<EndpointError>();
    public final EndpointLoggerContext logger;
    public final EndpointOrganizationContext organization;
    public final String requestId = System.Request.getCurrent().getRequestId();
    public final String transactionId = Nebula.Logger.getTransactionId();
    public final EndpointUserContext user;

    // Only 'result' or 'results' will be set (depending on which endpoint, parameters, and method are used)
    // There should not be a situation where both 'result' & 'results' are set
    public SObjectDTO result;
    public List<SObjectDTO> results;

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
        this.endpointRequest.context = new EndpointRequestContext();
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

  @TestVisible
  private class EndpointRequestContext {
    public final EndpointLoggerContext logger = new EndpointLoggerContext();
    public final EndpointOrganizationContext organization = new EndpointOrganizationContext();
    public final EndpointUserContext user = new EndpointUserContext();
  }
  @TestVisible
  private class EndpointLoggerContext {
    // FIXME The managed package currently doesn't have access to the method Logger.getNamespacePrefix(),
    // so there's not a great way to correctly set namespace without duplicating the logic
    public String namespace; // = Logger.getNamespacePrefix()
    public EndpointLoggerSettingsContext userSettings = new EndpointLoggerSettingsContext();
    public String versionNumber = Nebula.Logger.getVersionNumber();
  }

  @TestVisible
  private class EndpointLoggerSettingsContext {
    public Boolean isEnabled = Nebula.Logger.isEnabled();
    public String loggingLevel = Nebula.Logger.getUserLoggingLevel().name();
    public String saveMethod = Nebula.Logger.getSaveMethod()?.name();
  }

  @TestVisible
  private class EndpointOrganizationContext {
    // FIXME The managed package currently doesn't have access the method Logger.getOrganizationApiVersion(),
    // so there's not a great way to correctly set apiVersion without duplicating the logic
    public String apiVersion; // = Logger.getOrganizationApiVersion();
    public String baseDomain = System.URL.getOrgDomainUrl()?.toExternalForm();
    public String id = System.UserInfo.getOrganizationId();
    public String name = System.UserInfo.getOrganizationName();

    public EndpointOrganizationContext() {
      this.apiVersion = System.JSON.serialize(new Schema.User(Id = System.UserInfo.getUserId())).substringAfter('/data/').substringBefore('/sobjects/User');
    }
  }

  @TestVisible
  private class EndpointUserContext {
    public String id = System.UserInfo.getUserId();
    public String federationIdentifier = 'TODO - need to query this field, not provided via UserInfo';
    public String type = System.UserInfo.getUserType();
    public String username = System.UserInfo.getUsername();
  }

  /* Start of DTO classes for converting Nebula Logger's SObjects to a simplified representation that is returned as JSON */
  @TestVisible
  private abstract class SObjectDTO {
    // This property is intended to mimic the attributes property
    // that's included in SObject records. For example, this Apex code:
    //      JSON.serializePretty(new User(Id = Userinfo.getUserId())
    // ...includes an 'attributes' property in the JSON string:
    //      {"attributes":{"type":"User","url":"/services/data/v61.0/sobjects/User/00553000007b3HvAAI"},"Id":"00553000007b3HvAAI"}
    public final Map<String, String> attributes;

    public String id;
    public String name;

    protected SObjectDTO(String type) {
      this.attributes = new Map<String, String>{ 'type' => type };
    }
  }

  // DTOs for some standard objects
  public class ProfileDTO extends SObjectDTO {
    public ProfileDTO(String id, String name) {
      super('Profile');

      this.id = id;
      this.name = name;
    }
  }

  public class UserRoleDTO extends SObjectDTO {
    public UserRoleDTO(String id, String name) {
      super('UserRole');

      this.id = id;
      this.name = name;
    }
  }

  public class UserDTO extends SObjectDTO {
    public String federationIdentifier;
    public ProfileDTO profile;
    public String username;
    public UserRoleDTO userRole;

    public UserDTO() {
      super('User');
    }
  }

  @TestVisible
  private class LogDTO extends SObjectDTO {
    public String impersonatedById = 'TODO';
    public String impersonatedByFederationIdentifier = 'TODO';
    public String impersonatedByUsername = 'TODO';
    public List<LogEntryDTO> logEntries;
    // TODO either used loggedBy object, or String fields (not both)
    public UserDTO loggedBy; // TODO delete?
    public String loggedById;
    public String loggedByFederationIdentifier;
    public String loggedByUsername;
    public String originSystemName;
    public String originSystemReferenceId;
    public String parentLogTransactionId;
    public String profileId;
    public String profileName;
    public Datetime startTime;
    // TODO either used totalLogEntries map, or String fields (not both)
    public Map<String, Integer> totalLogEntries; // TODO delete?
    public Integer totalDEBUGLogEntries;
    public Integer totalERRORLogEntries;
    public Integer totalFINELogEntries;
    public Integer totalFINERLogEntries;
    public Integer totalFINESTLogEntries;
    public Integer totalINFOLogEntries;
    public Integer totalWARNLogEntries;
    public String transactionId;
    public String transactionScenario;
    public String userRoleId;
    public String userRoleName;

    public LogDTO() {
      super('Log');
    }

    public LogDTO(Nebula__Log__c logRecord) {
      this(logRecord, null);
    }

    public LogDTO(Nebula__Log__c logRecord, List<Nebula__LogEntry__c> logEntryRecords) {
      this();

      this.id = logRecord.Id;
      /* // TODO delete?
            this.loggedBy = new UserDTO();
            this.loggedBy.id = logRecord.Nebula__LoggedBy__c;
            // TODO the managed package does not yet have the field LoggedByFederationIdentifier__c
            this.loggedBy.federationIdentifier = 'TODO?';
            this.loggedBy.username = logRecord.Nebula__LoggedByUsername__c;
            // TODO keep?
            this.loggedByFederationIdentifier = 'TODO!'; // = logRecord.Nebula__LoggedByFederationIdentifier__c;
            this.loggedByFederationIdentifier = 'TODO!'; // = logRecord.Nebula__LoggedByFederationIdentifier__c;
            // TODO delete?
            this.loggedBy.profile = new ProfileDTO(logRecord.Nebula__ProfileId__c, logRecord.Nebula__ProfileName__c);
            // TODO keep?
            this.loggedBy.profileId = logRecord.Nebula__ProfileId__c;
            this.loggedBy.profileName = logRecord.Nebula__ProfileName__c;
            this.loggedBy.userRole = logRecord.Nebula__UserRoleId__c == null
                ? null
                : new UserRoleDTO(logRecord.Nebula__UserRoleId__c, logRecord.Nebula__UserRoleName__c); */

      this.loggedById = logRecord.Nebula__LoggedBy__c;
      // TODO the managed package does not yet have the field LoggedByFederationIdentifier__c
      // this.loggedByFederationIdentifier = logRecord.Nebula__LoggedByFederationIdentifier__c;
      this.loggedByFederationIdentifier = 'TODO';
      this.loggedByUsername = logRecord.Nebula__LoggedByUsername__c;
      this.name = logRecord.Name;
      this.originSystemName = 'TODO';
      this.originSystemReferenceId = 'TODO';
      this.parentLogTransactionId = logRecord.Nebula__ParentLog__r.Nebula__TransactionId__c;
      this.profileId = logRecord.Nebula__ProfileId__c;
      this.profileName = logRecord.Nebula__ProfileName__c;
      this.startTime = logRecord.Nebula__StartTime__c;
      this.totalDEBUGLogEntries = Integer.valueOf(logRecord.Nebula__TotalDEBUGLogEntries__c);
      this.totalERRORLogEntries = Integer.valueOf(logRecord.Nebula__TotalERRORLogEntries__c);
      this.totalFINELogEntries = Integer.valueOf(logRecord.Nebula__TotalFINELogEntries__c);
      this.totalFINERLogEntries = Integer.valueOf(logRecord.Nebula__TotalFINERLogEntries__c);
      this.totalFINESTLogEntries = Integer.valueOf(logRecord.Nebula__TotalFINESTLogEntries__c);
      this.totalINFOLogEntries = Integer.valueOf(logRecord.Nebula__TotalINFOLogEntries__c);
      this.totalWARNLogEntries = Integer.valueOf(logRecord.Nebula__TotalWARNLogEntries__c);
      // Delete?
      // this.totalLogEntries = new Map<String, Integer>{
      //     'error' => Integer.valueOf(logRecord.Nebula__TotalERRORLogEntries__c),
      //     'warn' => Integer.valueOf(logRecord.Nebula__TotalWARNLogEntries__c),
      //     'info' => Integer.valueOf(logRecord.Nebula__TotalINFOLogEntries__c),
      //     'debug' => Integer.valueOf(logRecord.Nebula__TotalDEBUGLogEntries__c),
      //     'fine' => Integer.valueOf(logRecord.Nebula__TotalFINELogEntries__c),
      //     'finer' => Integer.valueOf(logRecord.Nebula__TotalFINERLogEntries__c),
      //     'finest' => Integer.valueOf(logRecord.Nebula__TotalFINESTLogEntries__c)
      // };
      this.transactionId = logRecord.Nebula__TransactionId__c;
      // The transactionScenario property is intentionally mapped to UniqueId__c
      // because the standard Name field is only 80 characters long
      // and the UniqueId__c field is 255 characters, so it has the
      // correct/full name
      this.transactionScenario = logRecord.Nebula__TransactionScenarioText__c;
      this.userRoleId = logRecord.Nebula__UserRoleId__c;
      this.userRoleName = logRecord.Nebula__UserRoleName__c;

      this.setLogEntries(logEntryRecords);
    }

    private void setLogEntries(List<Nebula__LogEntry__c> logEntryRecords) {
      if (logEntryRecords == null) {
        return;
      }

      this.logEntries = new List<LogEntryDTO>();
      for (Nebula__LogEntry__c logEntryRecord : logEntryRecords) {
        this.logEntries.add(new LogEntryDTO(logEntryRecord));
      }
    }
  }

  @TestVisible
  private class LogEntryDTO extends SObjectDTO {
    // The entryScenario property is intentionally mapped to UniqueId__c
    // because the standard Name field is only 80 characters long
    // and the UniqueId__c field is 255 characters, so it has the
    // correct/full name
    public String entryScenario;
    // TODO confirm if anything needs to be done with data type/format
    // since epoch is originally a Long, but stored as Decimal
    public Decimal epochTimestamp;
    // TODO finalize a convention to be used for all DTO properties for things
    // like UUID/Uuid, URI/Uri, REST/Rest, etc
    // It probably makes the most sense to be consistent with the SObject fields,
    // like LogEntry__c.EventUuid__c field --> eventUuid property
    public String eventUuid;
    public String exceptionMessage;
    public String exceptionType;
    // TODO revert to using this or delete it
    // public Map<String, String> loggingLevel;
    public String loggingLevel;
    public String message;
    public String relatedRecordId;
    public List<String> tags;
    public Datetime timestamp;

    public LogEntryDTO() {
      super('LogEntry');
    }

    public LogEntryDTO(Nebula__LogEntry__c logEntryRecord) {
      this(logEntryRecord, null);
    }

    public LogEntryDTO(Nebula__LogEntry__c logEntryRecord, List<Nebula__LogEntryTag__c> logEntryTagRecords) {
      this();

      this.entryScenario = logEntryRecord.Nebula__EntryScenarioText__c;
      this.epochTimestamp = logEntryRecord.Nebula__EpochTimestamp__c;
      this.eventUuid = logEntryRecord.Nebula__EventUuid__c;
      this.exceptionMessage = logEntryRecord.Nebula__ExceptionMessage__c;
      this.exceptionType = logEntryRecord.Nebula__ExceptionType__c;
      this.id = logEntryRecord.Id;
      // this.loggingLevel = new Map<String, String>{
      //     'name' => logEntryRecord.Nebula__LoggingLevel__c,
      //     'ordinal' => logEntryRecord.Nebula__LoggingLevelOrdinal__c.toString()
      // };
      this.loggingLevel = logEntryRecord.Nebula__LoggingLevel__c;
      this.message = logEntryRecord.Nebula__Message__c;
      this.name = logEntryRecord.Name;
      this.relatedRecordId = logEntryRecord.Nebula__RecordId__c;
      this.timestamp = logEntryRecord.Nebula__Timestamp__c;

      this.setTags(logEntryTagRecords);
    }

    private void setTags(List<Nebula__LogEntryTag__c> logEntryTagRecords) {
      if (logEntryTagRecords == null) {
        return;
      }

      this.tags = new List<String>();
      for (Nebula__LogEntryTag__c logEntryTagRecord : logEntryTagRecords) {
        this.tags.add(logEntryTagRecord.Nebula__Tag__r.Nebula__UniqueId__c);
      }
    }
  }

  @TestVisible
  private class LoggerScenarioDTO extends SObjectDTO {
    public List<LogDTO> logs;
    public List<LogEntryDTO> logEntries;

    public LoggerScenarioDTO(Nebula__LoggerScenario__c loggerScenarioRecord, List<Nebula__Log__c> logs, List<Nebula__LogEntry__c> logEntries) {
      this();

      this.id = loggerScenarioRecord.id;
      // The name property is intentionally mapped to UniqueId__c
      // because the standard Name field is only 80 characters long
      // and the UniqueId__c field is 255 characters, so it has the
      // correct/full name
      this.name = loggerScenarioRecord.Nebula__UniqueId__c;

      this.setLogs(logs);
      this.setLogEntries(logEntries);
    }

    public LoggerScenarioDTO() {
      super('LoggerScenario');
    }

    private void setLogs(List<Nebula__Log__c> logRecords) {
      if (logRecords == null) {
        return;
      }

      this.logs = new List<LogDTO>();
      for (Nebula__Log__c logRecord : logRecords) {
        this.logs.add(new LogDTO(logRecord));
      }
    }

    private void setLogEntries(List<Nebula__LogEntry__c> logEntryRecords) {
      if (logEntryRecords == null) {
        return;
      }

      this.logEntries = new List<LogEntryDTO>();
      for (Nebula__LogEntry__c logEntryRecord : logEntryRecords) {
        // TODO in this situation, it could be helpful for each LogEntryDTO to have a reference to its parent LogDTO,
        // since the entries in the 'logEntries' property is separate from the logs in the 'logs' property
        this.logEntries.add(new LogEntryDTO(logEntryRecord, logEntryRecord.Nebula__LogEntryTags__r));
      }
    }
  }

  @TestVisible
  private class LoggerTagDTO extends SObjectDTO {
    public List<LogEntryDTO> logEntries;
    public String name;

    public LoggerTagDTO(Nebula__LoggerTag__c loggerTagRecord, List<Nebula__LogEntry__c> logEntryRecords) {
      this();

      this.name = loggerTagRecord.Nebula__UniqueId__c;

      this.setLogEntries(logEntryRecords);
    }

    public LoggerTagDTO() {
      super('LoggerTag');
    }

    private void setLogEntries(List<Nebula__LogEntry__c> logEntryRecords) {
      if (logEntryRecords == null) {
        return;
      }

      this.logEntries = new List<LogEntryDTO>();
      for (Nebula__LogEntry__c logEntryRecord : logEntryRecords) {
        this.logEntries.add(new LogEntryDTO(logEntryRecord));
      }
    }
  }
  /* End of DTO classes for converting Nebula Logger's SObjects to a simplified representation that is returned as JSON */

  /* Classes for dynamic query building 😐 */
  private class QueryFilter {
    public String field;
    public String operator;
    public Object value;

    public QueryFilter(String field, String operator, Object value) {
      this.field = field;
      this.operator = operator;
      this.value = value;
    }
  }

  /* Endpoints */
  private class LogsEndpoint extends Endpoint {
    public override EndpointResponse handleGet(EndpointRequest endpointRequest) {
      String possibleTransactionId = endpointRequest.particle;
      if (possibleTransactionId != null) {
        return this.queryLog(endpointRequest);
      } else {
        return this.searchLogs(endpointRequest);
      }
    }

    public override EndpointResponse handlePost(EndpointRequest endpointRequest) {
      EndpointResponse postResponse = new EndpointResponse(endpointRequest);
      try {
        LogDTO logToCreate = this.deserializeLog(endpointRequest.body);
        this.saveLog(logToCreate);
        postResponse.setStatusCode(STATUS_CODE_201_CREATED);
        return postResponse;
      } catch (Exception apexException) {
        postResponse.setStatusCode(STATUS_CODE_400_BAD_REQUEST).addError(apexException);
        return postResponse;
      }
    }

    private EndpointResponse queryLog(EndpointRequest endpointRequest) {
      EndpointResponse endpointResponse = new EndpointResponse(endpointRequest);

      try {
        System.UUID.fromString(endpointRequest.particle);
      } catch (System.IllegalArgumentException invalidUuidException) {
        endpointResponse.setStatusCode(STATUS_CODE_400_BAD_REQUEST).addError(invalidUuidException);
        return endpointResponse;
      }

      // TODO move query to a selector class
      List<Nebula__Log__c> matchingLogRecords = [
        SELECT
          Id,
          Name,
          Nebula__LoggedBy__c,
          Nebula__LoggedByUsername__c,
          Nebula__ParentLog__r.Nebula__TransactionId__c,
          Nebula__ProfileId__c,
          Nebula__ProfileName__c,
          Nebula__StartTime__c,
          Nebula__TotalDEBUGLogEntries__c,
          Nebula__TotalERRORLogEntries__c,
          Nebula__TotalFINELogEntries__c,
          Nebula__TotalFINERLogEntries__c,
          Nebula__TotalFINESTLogEntries__c,
          Nebula__TotalINFOLogEntries__c,
          Nebula__TotalWARNLogEntries__c,
          Nebula__TransactionId__c,
          Nebula__TransactionScenarioText__c,
          Nebula__UserRoleId__c,
          Nebula__UserRoleName__c,
          (
            SELECT
              Id,
              Name,
              Nebula__EntryScenarioText__c,
              Nebula__EpochTimestamp__c,
              Nebula__EventUuid__c,
              Nebula__ExceptionMessage__c,
              Nebula__ExceptionType__c,
              Nebula__LoggingLevel__c,
              Nebula__LoggingLevelOrdinal__c,
              Nebula__Message__c,
              Nebula__RecordId__c,
              Nebula__Timestamp__c,
              (SELECT Nebula__Tag__r.Nebula__UniqueId__c FROM Nebula__LogEntryTags__r)
            FROM Nebula__LogEntries__r
          )
        FROM Nebula__Log__c
        WHERE Nebula__TransactionId__c = :endpointRequest.particle
      ];

      if (matchingLogRecords.isEmpty()) {
        // TODO decide for sure on what behavior should be used when no matches are found
        String errorMessage = 'No matching logs found for transaction ID: ' + endpointRequest.particle;
        System.NoDataFoundException noDataFoundException = new System.NoDataFoundException();
        noDataFoundException.setMessage(errorMessage);

        endpointResponse.addError(noDataFoundException);
      } else {
        Nebula__Log__c matchingLogRecord = matchingLogRecords.get(0);
        endpointResponse.result = new LogDTO(matchingLogRecord, matchingLogRecord.Nebula__LogEntries__r);
      }
      endpointResponse.setStatusCode(STATUS_CODE_200_OK);

      return endpointResponse;
    }

    private EndpointResponse searchLogs(EndpointRequest endpointRequest) {
      List<QueryFilter> filters = new List<QueryFilter>();
      List<String> filterStrings = new List<String>();

      List<String> queryFieldNames = new List<String>(Schema.Nebula__Log__c.SObjectType.getDescribe().fields.getMap().keySet());
      String parentLogRelationshipName = Nebula__Log__c.Nebula__ParentLog__c.getDescribe().getRelationshipName();
      queryFieldNames.add(parentLogRelationshipName + '.' + Nebula__Log__c.Nebula__TransactionId__c.getDescribe().getName());
      // String fieldClause = 'Id, Name';
      String queryFieldsClause = String.join(queryFieldNames, ', ');

      Integer bindVarCount = 0;
      Map<String, Object> bindKeyToValue = new Map<String, Object>();

      String minStartDateFilter = 'minStartDate';
      if (endpointRequest.parameters.containsKey(minStartDateFilter)) {
        String field = Schema.Nebula__Log__c.Nebula__StartTime__c.getDescribe().getName();
        Date value = Date.valueOf(endpointRequest.parameters.get(minStartDateFilter));

        // System.Assert.fail('minStartDate value=' + value);

        String bindKey = 'bindVar' + bindVarCount;
        bindKeyToValue.put(bindKey, value);
        // QueryFilter filter = new QueryFilter(field, '>=', value);
        // filters.add(filter);
        filterStrings.add(field + ' >= :' + bindKey);
      }

      String queryFiltersClause = filterStrings.isEmpty() ? '' : 'WHERE ' + String.join(filterStrings, ' AND ');

      String queryTemplate = 'SELECT {0} FROM {1} {2} ORDER BY {3} DESC LIMIT {4}';
      String query = String.format(
        queryTemplate,
        new List<Object>{
          queryFieldsClause,
          Schema.Nebula__Log__c.SObjectType.toString(),
          queryFiltersClause,
          Schema.Nebula__Log__c.Nebula__StartTime__c.toString(),
          20
        }
      );
      // System.Assert.fail('query=' + query);
      List<Nebula__Log__c> matchingLogRecords = System.Database.queryWithBinds(query, bindKeyToValue, System.AccessLevel.USER_MODE);

      List<LogDTO> logs = new List<LogDTO>();
      for (Nebula__Log__c logRecord : matchingLogRecords) {
        logs.add(new LogDTO(logRecord, logRecord.Nebula__LogEntries__r));
      }

      // TODO implement search, using endpointRequest.parameters for search criteria
      // return new EndpointResponse(endpointRequest).addError(new EndpointError('oops'));
      EndpointResponse endpointResponse = new EndpointResponse(endpointRequest);
      endpointResponse.results = logs;
      return endpointResponse;
    }

    private void saveLog(LogDTO logCreateRequest) {
      Nebula.Logger.setParentLogTransactionId(logCreateRequest.parentLogTransactionId);
      Nebula.Logger.setScenario(logCreateRequest.transactionScenario);

      for (LogEntryDTO logEntryCreateRequest : logCreateRequest.logEntries) {
        // TODO need to revisit the shape of loggingLevel - should it be a string, or a Map/inner class?
        // For inbound requests to create a log, it's easier for developers to just pass a string
        // For responses, having loggingLevel as a Mapl/inner class might make the JSON more readable...?
        // System.LoggingLevel loggingLevel = Nebula.Logger.getLoggingLevel(logEntryCreateRequest.loggingLevel.get('name'));
        System.LoggingLevel loggingLevel = Nebula.Logger.getLoggingLevel(logEntryCreateRequest.loggingLevel);
        Nebula.Logger.newEntry(loggingLevel, logEntryCreateRequest.message)
          // FIXME The managed package currently doesn't have a way to set the value
          // of OriginType__c = 'API'
          .setRecord(logEntryCreateRequest.relatedRecordId)
          // FIXME The managed package currently doesn't have the .setTimestamp() builder method,
          // so there's not a great way to correctly set the Timestamp__c field yet
          // .setTimestamp(logEntryCreateRequest.timestamp)
          .addTags(logEntryCreateRequest.tags);
      }

      Nebula.Logger.saveLog();
    }

    private LogDTO deserializeLog(String jsonBody) {
      if (String.isBlank(jsonBody)) {
        throw new System.IllegalArgumentException('No data provided');
      }

      LogDTO logToCreate = (LogDTO) System.JSON.deserialize(jsonBody, LogDTO.class);

      // TODO add support for adding these as errors in logToCreate.errors
      // (instead of only bubbling up 1 via throwing an exception)
      if (String.isBlank(logToCreate.originSystemName)) {
        throw new System.IllegalArgumentException('No data provided for required property "originSystemName"');
      }

      if (logToCreate.logEntries == null || logToCreate.logEntries.isEmpty()) {
        throw new System.IllegalArgumentException('No data provided for required property "logEntries"');
      }

      return logToCreate;
    }
  }

  private class LogEntriesEndpoint extends Endpoint {
    // TODO
  }

  private class LoggerScenariosEndpoint extends Endpoint {
    // TODO
  }

  private class LoggerTagsEndpoint extends Endpoint {
    // TODO
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
}
