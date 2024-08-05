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
    private static final Boolean SUPPRESS_NULLS_IN_JSON_SERIALIZATION = true;

    @HttpGet
    global static void handleGet() {
        EndpointRequest endpointRequest = new EndpointRequest(System.RestContext.request);
        Endpoint endpoint = getEndpoint(endpointRequest.name);

        EndpointResponse endpointResponse = endpoint.handleGet(endpointRequest);
        System.RestContext.response = buildRestResponse(endpointResponse);
    }

    @HttpPost
    global static void handlePost() {
        EndpointRequest endpointRequest = new EndpointRequest(System.RestContext.request);
        Endpoint endpoint = getEndpoint(endpointRequest.name);

        EndpointResponse endpointResponse = endpoint.handlePost(endpointRequest);
        System.RestContext.response = buildRestResponse(endpointResponse);
    }

    private static Endpoint getEndpoint(String endpointName) {
        switch on endpointName {
            when 'logger-scenarios' {
                return new LoggerScenariosEndpoint();
            }
            when 'logs' {
                return new LogsEndpoint();
            }
            when 'log-entries' {
                return new LogEntriesEndpoint();
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

    /* Base classes that act as the building blocks for all endpoints */
    private abstract class Endpoint {
        // For now, only GET & POST are used by Nebula Logger, so there's no need to have methods
        // for the other HTTP verbs DELETE, PATCH, and PUT.
        public virtual EndpointResponse handleGet(EndpointRequest endpointRequest) {
            throw new System.IllegalArgumentException('Unsupported method: GET');
        }

        public virtual EndpointResponse handlePost(EndpointRequest endpointRequest) {
            throw new System.IllegalArgumentException('Unsupported method: POST');
        }
    }

    @TestVisible
    private class EndpointRequest {
        public String body;
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
            if (String.isBlank(parsedEndpointParticle)) {
                parsedEndpointParticle = null;
            }
            return parsedEndpointParticle;
        }
    }

    @TestVisible
    private virtual class EndpointResponse {
        // public final EndpointRequest endpointRequest;
        public final List<EndpointError> errors = new List<EndpointError>();
        public final EndpointLoggerContext logger;
        public final EndpointOrganizationContext organization;
        public final String requestId = System.Request.getCurrent().getRequestId();
        public final String transactionId = Nebula.Logger.getTransactionId();
        public final EndpointUserContext user;

        public transient Integer statusCode;

        public Boolean isSuccess {
            get {
                return this.errors.isEmpty();
            }
        }

        public EndpointResponse(EndpointRequest endpointRequest) {
            if (this.isTruthy(endpointRequest.parameters, 'verbose')) {
                // TODO revisit to decide if/what endpoint info should be returned in the reponse
                // this.endpointRequest = endpointRequest;
                this.logger = new EndpointLoggerContext();
                this.organization = new EndpointOrganizationContext();
                this.user = new EndpointUserContext();
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
            return (parameters.containsKey(targetParameterName) && parameterStringValue == null) ||
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
            this.apiVersion = System.JSON.serialize(new Schema.User(Id = System.UserInfo.getUserId()))
                .substringAfter('/data/')
                .substringBefore('/sobjects/User');
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
    private class LoggerScenarioDTO {
        public List<LogDTO> logs;
        public List<LogEntryDTO> logEntries;
        public String name;

        public LoggerScenarioDTO(Nebula__LoggerScenario__c loggerScenario, List<Nebula__Log__c> logs, List<Nebula__LogEntry__c> logEntries) {
            this.name = loggerScenario.Nebula__UniqueId__c;

            this.setLogs(logs);
            this.setLogEntries(logEntries);
        }

        private void setLogs(List<Nebula__Log__c> logs) {
            if (logs == null) {
                return;
            }

            this.logs = new List<LogDTO>();
            for (Nebula__Log__c log : logs) {
                this.logs.add(new LogDTO(log));
            }
        }

        private void setLogEntries(List<Nebula__LogEntry__c> logEntries) {
            if (logEntries == null) {
                return;
            }

            this.logEntries = new List<LogEntryDTO>();
            for (Nebula__LogEntry__c logEntry : logEntries) {
                this.logEntries.add(new LogEntryDTO(logEntry, logEntry.Nebula__LogEntryTags__r));
            }
        }
    }

    @TestVisible
    private class LogDTO {
        public List<LogEntryDTO> logEntries;
        // TODO consider making 'logged by' fields into an instance
        // of EndpointUserContext (perhaps with a new class name?)
        public String loggedById;
        public String loggedByFederationIdentifier;
        public String loggedByUsername;
        public String originSystemName;
        public String originSystemReferenceId;
        public String parentLogTransactionId;
        public String transactionId;
        public String transactionScenario;

        public LogDTO() {
            // No-op - used by tests to mock this
        }

        public LogDTO(Nebula__Log__c log) {
            this(log, null);
        }

        public LogDTO(Nebula__Log__c log, List<Nebula__LogEntry__c> logEntries) {
            this();
            this.loggedById = log.Nebula__LoggedBy__c;
            // TODO the managed package does not yet have the field LoggedByFederationIdentifier__c
            // this.loggedByFederationIdentifier = log.Nebula__LoggedByFederationIdentifier__c;
            this.loggedByFederationIdentifier = 'TODO';
            this.loggedByUsername = log.Nebula__LoggedByUsername__c;
            this.originSystemName = 'TODO';
            this.originSystemReferenceId = 'TODO';
            this.parentLogTransactionId = log.Nebula__ParentLog__r.Nebula__TransactionId__c;
            this.transactionId = log.Nebula__TransactionId__c;
            this.transactionScenario = log.Nebula__TransactionScenario__r.Nebula__UniqueId__c;

            this.setLogEntries(logEntries);
        }

        private void setLogEntries(List<Nebula__LogEntry__c> logEntries) {
            if (logEntries == null) {
                return;
            }

            this.logEntries = new List<LogEntryDTO>();
            for (Nebula__LogEntry__c logEntry : logEntries) {
                this.logEntries.add(new LogEntryDTO(logEntry));
            }
        }
    }

    @TestVisible
    private class LogEntryDTO {
        public String loggingLevel;
        public String message;
        public String relatedRecordId;
        public List<String> tags;
        public Datetime timestamp;

        public LogEntryDTO() {
            // No-op - used by tests to mock this
        }

        public LogEntryDTO(Nebula__LogEntry__c logEntry) {
            this(logEntry, null);
        }

        public LogEntryDTO(Nebula__LogEntry__c logEntry, List<Nebula__LogEntryTag__c> logEntryTags) {
            this();
            this.loggingLevel = logEntry.Nebula__LoggingLevel__c;
            this.message = logEntry.Nebula__Message__c;
            this.relatedRecordId = logEntry.Nebula__RecordId__c;
            this.timestamp = logEntry.Nebula__Timestamp__c;

            this.setTags(logEntryTags);
        }

        private void setTags(List<Nebula__LogEntryTag__c> logEntryTags) {
            if (logEntryTags == null) {
                return;
            }

            this.tags = new List<String>();
            for (Nebula__LogEntryTag__c logEntryTag : logEntryTags) {
                this.tags.add(logEntryTag.Nebula__Tag__r.Nebula__UniqueId__c);
            }
        }
    }

    @TestVisible
    private class LoggerTagDTO {
        public List<LogEntryDTO> logEntries;
        public String name;

        public LoggerTagDTO(Nebula__LoggerTag__c loggerTag, List<Nebula__LogEntry__c> logEntries) {
            this.name = loggerTag.Nebula__UniqueId__c;

            this.setLogEntries(logEntries);
        }

        private void setLogEntries(List<Nebula__LogEntry__c> logEntries) {
            if (logEntries == null) {
                return;
            }

            this.logEntries = new List<LogEntryDTO>();
            for (Nebula__LogEntry__c logEntry : logEntries) {
                this.logEntries.add(new LogEntryDTO(logEntry));
            }
        }
    }
    /* End of DTO classes for converting Nebula Logger's SObjects to a simplified representation that is returned as JSON */

    /* Start of '/logger-scenarios' endpoint classes */
    @TestVisible
    private class LoggerScenariosEndpointResponse extends EndpointResponse {
        public List<LoggerScenarioDTO> logScenarios;

        public LoggerScenariosEndpointResponse(EndpointRequest endpointRequest) {
            super(endpointRequest);
        }
    }

    private class LoggerScenariosEndpoint extends Endpoint {
        // TODO
    }
    /* End of '/logger-scenarios' endpoint classes */

    /* Start of '/logs' endpoint classes */
    @TestVisible
    private class LogsEndpointResponse extends EndpointResponse {
        // Only log or logs will be set (depending on which endpoint parameters & method are used)
        // There should not be a situation where both log & logs are set
        public LogDto log;
        public List<LogDto> logs;

        public LogsEndpointResponse(EndpointRequest endpointRequest) {
            super(endpointRequest);
        }
    }

    private class LogsEndpoint extends Endpoint {
        public override EndpointResponse handleGet(EndpointRequest endpointRequest) {
            String possibleTransactionId = endpointRequest.particle;
            if (possibleTransactionId == null) {
                return this.searchLogs(endpointRequest);
            } else {
                return this.queryLog(endpointRequest);
            }
        }

        public override EndpointResponse handlePost(EndpointRequest endpointRequest) {
            EndpointResponse postResponse = new EndpointResponse(endpointRequest);
            try {
                this.saveLogRequest(endpointRequest);
                postResponse.setStatusCode(200);
                return postResponse;
            } catch (Exception apexException) {
                postResponse.setStatusCode(400).addError(apexException);
                return postResponse;
            }
        }

        private EndpointResponse searchLogs(EndpointRequest endpointRequest) {
            // TODO implement search, using endpointRequest.parameters for search criteria
            return null;
        }

        private EndpointResponse queryLog(EndpointRequest endpointRequest) {
            LogsEndpointResponse endpointResponse = new LogsEndpointResponse(endpointRequest);

            try {
                System.UUID.fromString(endpointRequest.particle);
            } catch (System.IllegalArgumentException invalidUuidException) {
                endpointResponse.addError(invalidUuidException);
                return endpointResponse;
            }

            // TODO move query to a selector class
            List<Nebula__Log__c> matchingLogs = [
                SELECT
                    Nebula__LoggedBy__c,
                    Nebula__LoggedByUsername__c,
                    Nebula__ParentLog__r.Nebula__TransactionId__c,
                    Nebula__TransactionId__c,
                    Nebula__TransactionScenario__r.Nebula__UniqueId__c,
                    (
                        SELECT
                            Nebula__LoggingLevel__c,
                            Nebula__Message__c,
                            Nebula__RecordId__c,
                            Nebula__Timestamp__c,
                            (SELECT Nebula__Tag__r.Nebula__UniqueId__c FROM Nebula__LogEntryTags__r)
                        FROM Nebula__LogEntries__r
                    )
                FROM Nebula__Log__c
                WHERE Nebula__TransactionId__c = :endpointRequest.particle
            ];


            if (matchingLogs.isEmpty()) {
                String errorMessage = 'No matching logs found for transaction ID: ' + endpointRequest.particle;
                System.NoDataFoundException noDataFoundException = new System.NoDataFoundException();
                noDataFoundException.setMessage(errorMessage);

                endpointResponse.setStatusCode(400).addError(noDataFoundException);
            } else {
                Nebula__Log__c matchingLog = matchingLogs.get(0);
                endpointResponse.log = new LogDTO(matchingLog, matchingLog.Nebula__LogEntries__r);

                endpointResponse.setStatusCode(200);
            }

            return endpointResponse;
        }

        private void saveLogRequest(EndpointRequest endpointRequest) {
            LogDTO logCreateRequest = this.deserializeLogRequest(endpointRequest.body);

            Nebula.Logger.setParentLogTransactionId(logCreateRequest.parentLogTransactionId);
            Nebula.Logger.setScenario(logCreateRequest.transactionScenario);

            for (LogEntryDTO logEntryCreateRequest : logCreateRequest.logEntries) {
                System.LoggingLevel loggingLevel = Nebula.Logger.getLoggingLevel(logEntryCreateRequest.loggingLevel);
                Nebula.Logger.newEntry(loggingLevel, logEntryCreateRequest.message)
                    // FIXME The managed package currently doesn't have a way to set the value
                    // of OriginType__c = 'Integration'
                    .setRecord(logEntryCreateRequest.relatedRecordId)
                    // FIXME The managed package currently doesn't have the .setTimestamp() builder method,
                    // so there's not a great way to correctly set the Timestamp__c field yet
                    // .setTimestamp(logEntryCreateRequest.timestamp)
                    .addTags(logEntryCreateRequest.tags);
            }

            Nebula.Logger.saveLog();
        }

        private LogDTO deserializeLogRequest(String jsonBody) {
            if (String.isBlank(jsonBody)) {
                throw new System.IllegalArgumentException('No data provided');
            }

            LogDTO logCreateRequest = (LogDTO) System.JSON.deserialize(jsonBody, LogDTO.class);

            // TODO add support for adding these as errors in logCreateRequest.errors
            // (instead of only bubbling up 1 via throwing an exception)
            if (String.isBlank(logCreateRequest.originSystemName)) {
                throw new System.IllegalArgumentException('No data provided for required property "originSystemName"');
            }

            if (logCreateRequest.logEntries == null || logCreateRequest.logEntries.isEmpty()) {
                throw new System.IllegalArgumentException('No data provided for required property "logEntries"');
            }

            return logCreateRequest;
        }
    }
    /* end of '/logs' endpoint classes */

    /* Start of '/log-entries' endpoint classes */
    @TestVisible
    private class LogEntriesEndpointResponse extends EndpointResponse {
        public List<LogEntryDTO> logEntries;

        public LogEntriesEndpointResponse(EndpointRequest endpointRequest) {
            super(endpointRequest);
        }
    }

    private class LogEntriesEndpoint extends Endpoint {
        // TODO
    }
    /* End of '/log-entries' endpoint classes */

    /* Start of '/logger-tags' endpoint classes */
    @TestVisible
    private class LoggerTagsEndpointResponse extends EndpointResponse {
        public List<LoggerTagDTO> loggerTags;

        public LoggerTagsEndpointResponse(EndpointRequest endpointRequest) {
            super(endpointRequest);
        }
    }

    private class LoggerTagsEndpoint extends Endpoint {
        // TODO
    }
    /* End of '/logger-tags' endpoint classes */

    private class UnknownEndpointResponder extends Endpoint {
        public override EndpointResponse handleGet(EndpointRequest endpointRequest) {
            return this.handleResponse(endpointRequest);
        }

        public override EndpointResponse handlePost(EndpointRequest endpointRequest) {
            return this.handleResponse(endpointRequest);
        }

        private EndpointResponse handleResponse(EndpointRequest endpointRequest) {
            // TODO decide if it still makes sense to log here, especially if restRequest & restResponse are no longer in scope
            // Nebula.Logger.warn(errorMessage).setRestRequestDetails(restRequest).setRestResponseDetails(restResponse);
            // Nebula.Logger.saveLog();

            String errorMessage = 'Unknown endpoint provided: ' + endpointRequest.name;
            return new EndpointResponse(endpointRequest).setStatusCode(404).addError(new EndpointError(errorMessage));
        }
    }
}
