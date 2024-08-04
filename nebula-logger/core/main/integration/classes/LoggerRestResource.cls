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
        Endpoint endpoint;
        switch on endpointRequest.name {
            when 'logger-scenarios' {
                endpoint = new LoggerScenariosEndpoint();
            }
            when 'logs' {
                endpoint = new LogsEndpoint();
            }
            when 'log-entries' {
                endpoint = new LogEntriesEndpoint();
            }
            when 'logger-tags' {
                endpoint = new LoggerTagsEndpoint();
            }
            when else {
                endpoint = new UnknownEndpointResponder(endpointRequest.name);
            }
        }
        System.RestContext.response = initializeRestResponse();
        endpoint.handleGet(System.RestContext.request, System.RestContext.response);
    }

    @HttpPost
    global static void handlePost() {
        EndpointRequest endpointRequest = new EndpointRequest(System.RestContext.request);
        Endpoint endpoint;
        switch on endpointRequest.name {
            when 'logs' {
                endpoint = new LogsEndpoint();
            }
            when else {
                endpoint = new UnknownEndpointResponder(endpointRequest.name);
            }
        }
        System.RestContext.response = initializeRestResponse();
        endpoint.handlePost(System.RestContext.request, System.RestContext.response);
    }

    private static System.RestResponse initializeRestResponse() {
        System.RestResponse restResponse = System.RestContext.response ?? new System.RestResponse();
        restResponse.addHeader('Content-Type', 'application/json');
        return restResponse;
    }

    /* Base classes that act as the building blocks for all endpoints */
    private abstract class Endpoint {
        // For now, only GET & POST are used by Nebula Logger, so there's no need to have methods
        // for the other HTTP verbs DELETE, PATCH, and PUT.

        // TODO eliminate param System.RestResponse restResponse, and replace with a return value of EndpointResponse
        public virtual void handleGet(EndpointRequest endpointRequest, System.RestResponse restResponse) {
            throw new System.IllegalArgumentException('Unsupported method: GET');
        }

        // TODO eliminate param System.RestResponse restResponse, and replace with a return value of EndpointResponse
        public virtual void handlePost(EndpointRequest endpointRequest, System.RestResponse restResponse) {
            throw new System.IllegalArgumentException('Unsupported method: POST');
        }

        // TODO Delete everything below
        public virtual void handleGet(System.RestRequest restRequest, System.RestResponse restResponse) {
            throw new System.IllegalArgumentException('Unsupported method: GET');
        }

        public virtual void handlePost(System.RestRequest restRequest, System.RestResponse restResponse) {
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
            this.body = restRequest.requestBody?.toString() ?? null;
            this.headerKeys = new List<String>(restRequest.headers.keySet());
            this.parameters = restRequest.params;
            this.uri = restRequest.requestURI;

            this.parseUri(restRequest.requestUri);
        }

        private void parseUri(String restRequestUri) {
            this.name = this.getEndpointName(restRequestUri);
            this.particle = this.getEndpointParticle(restRequestUri, this.name);

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
        // public final EndpointRequestContext endpoint;
        public final List<EndpointError> errors = new List<EndpointError>();
        public final EndpointLoggerContext logger;
        public final EndpointOrganizationContext organization;
        public final String requestId = System.Request.getCurrent().getRequestId();
        public final String transactionId = Nebula.Logger.getTransactionId();
        public final EndpointUserContext user;

        public Boolean isSuccess {
            get {
                return this.errors.isEmpty();
            }
        }

        public EndpointResponse(EndpointRequest endpointRequest) {
            if (this.shouldIncludeVerboseContext(endpointRequest.parameters)) {
                // TODO revisit to decide if/what endpoint info should be returned in the reponse
                // this.endpoint = new EndpointRequestContext(restRequest);
                this.logger = new EndpointLoggerContext();
                this.organization = new EndpointOrganizationContext();
                this.user = new EndpointUserContext();
            }
        }


        private Boolean shouldIncludeVerboseContext(Map<String, String> parameters) {
            return parameters.get('verbose') == 'true';
        }

        // TODO delete everything below
        public EndpointResponse(System.RestRequest restRequest) {
            if (this.shouldIncludeVerboseContext(restRequest)) {
                // TODO revisit to decide if/what endpoint info should be returned in the reponse
                // this.endpoint = new EndpointRequestContext(restRequest);
                this.logger = new EndpointLoggerContext();
                this.organization = new EndpointOrganizationContext();
                this.user = new EndpointUserContext();
            }
        }

        private Boolean shouldIncludeVerboseContext(System.RestRequest restRequest) {
            return restRequest.params.get('verbose') == 'true';
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

    // @TestVisible
    // private class EndpointRequestContext {
    //     public List<String> headerKeys;
    //     public String name;
    //     public Map<String, String> parameters;
    //     public String uri;

    //     public EndpointRequestContext(System.RestRequest restRequest) {
    //         this.headerKeys = new List<String>(System.RestContext.request.headers.keySet());
    //         // TODO revisit, this is using a static method from top-level class
    //         this.name = getEndpointName(restRequest);
    //         this.parameters = restRequest.params;
    //         this.uri = restRequest.requestURI;
    //     }
    // }

    @TestVisible
    private class EndpointUserContext {
        public String id = System.UserInfo.getUserId();
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
    private class LoggerScenariosEndpoint extends Endpoint {
        // TODO
    }
    /* End of '/logger-scenarios' endpoint classes */

    /* Start of '/logs' endpoint classes */
    @TestVisible
    private class LogsSingularGetResponse extends EndpointResponse {
        public LogDto log;

        public LogsSingularGetResponse(EndpointRequest endpointRequest) {
            super(endpointRequest);
        }
    }

    @TestVisible
    private class LogsCollectionGetResponse extends EndpointResponse {
        public List<LogDto> logs;

        public LogsCollectionGetResponse(EndpointRequest endpointRequest) {
            super(endpointRequest);
        }
    }

    private class LogsEndpoint extends Endpoint {
        public override void handleGet(EndpointRequest endpointRequest, System.RestResponse restResponse) {
            String possibleTransactionId = endpointRequest.particle;
            if (possibleTransactionId == null) {
                this.searchLogs(endpointRequest, restResponse);
            } else {
                this.getSingleLog(endpointRequest, restResponse);
            }
        }

        public override void handlePost(System.RestRequest restRequest, System.RestResponse restResponse) {
            try {
                this.saveLogRequest(restRequest);
                EndpointResponse logCreateResponse = new EndpointResponse(restRequest);
                restResponse.responseBody = Blob.valueOf(System.JSON.serialize(logCreateResponse, SUPPRESS_NULLS_IN_JSON_SERIALIZATION));
                restResponse.statusCode = 200;
            } catch (Exception apexException) {
                EndpointResponse errorResponse = new EndpointResponse(restRequest);
                errorResponse.errors.add(new EndpointError(apexException));
                restResponse.responseBody = Blob.valueOf(System.JSON.serialize(errorResponse, SUPPRESS_NULLS_IN_JSON_SERIALIZATION));
                restResponse.statusCode = 400;

                Nebula.Logger.error('Failed to save external log', apexException).setRestRequestDetails(restRequest).setRestResponseDetails(restResponse);
                Nebula.Logger.saveLog();
            }
        }

        private void searchLogs(EndpointRequest endpointRequest, System.RestResponse restResponse) {
            // TODO implement
        }

        private void getSingleLog(EndpointRequest endpointRequest, System.RestResponse restResponse) {
            Boolean isValidUuid = false;
            try {
                System.UUID.fromString(endpointRequest.particle);
                isValidUuid = true;
            } catch(System.IllegalArgumentException invalidUuidException) {
                isValidUuid = false;
            }

            if (isValidUuid == false) {
                // TODO throw an error of some sort
            }


            // TODO move query to a selector class
            List<Nebula__Log__c> matchingLogs = [
                SELECT
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
                EndpointResponse failureResponse = new EndpointResponse(endpointRequest);
                failureResponse.errors.add(new EndpointError(noDataFoundException));
                restResponse.responseBody = Blob.valueOf(System.JSON.serialize(failureResponse, SUPPRESS_NULLS_IN_JSON_SERIALIZATION));
                restResponse.statusCode = 400;
            } else {
                Nebula__Log__c matchingLog = matchingLogs.get(0);
                LogsSingularGetResponse logGetResponse = new LogsSingularGetResponse(endpointRequest);
                logGetResponse.log = new LogDTO(matchingLog, matchingLog.Nebula__LogEntries__r);

                restResponse.responseBody = Blob.valueOf(System.JSON.serialize(logGetResponse, SUPPRESS_NULLS_IN_JSON_SERIALIZATION));
                restResponse.statusCode = 200;
            }
        }

        private void saveLogRequest(System.RestRequest restRequest) {
            // LogCreateSummary logCreateSummary = new LogCreateSummary();

            LogDTO logCreateRequest = this.deserializeLogRequest(restRequest);
            // logCreateSummary.logEntriesSent = logCreateRequest.logEntries?.size() ?? 0;

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
            // Capture the number of log entries in the buffer just before calling saveLog(),
            // since saveLog() will then flush the buffer
            // logCreateSummary.logEntriesSaved = Nebula.Logger.getBufferSize();
            Nebula.Logger.saveLog();

            // return logCreateSummary;
        }

        private LogDTO deserializeLogRequest(System.RestRequest restRequest) {
            if (String.isBlank(restRequest?.requestBody?.toString())) {
                throw new System.IllegalArgumentException('No data provided');
            }

            LogDTO logCreateRequest = (LogDTO) System.JSON.deserialize(restRequest.requestBody.toString(), LogDTO.class);

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
    private class LogEntriesEndpoint extends Endpoint {
        // TODO
    }
    /* End of '/log-entries' endpoint classes */

    /* Start of '/logger-tags' endpoint classes */
    private class LoggerTagsEndpoint extends Endpoint {
        // TODO
    }
    /* End of '/logger-tags' endpoint classes */

    private class UnknownEndpointResponder extends Endpoint {
        private final String endpointName;

        public UnknownEndpointResponder(String endpointName) {
            this.endpointName = endpointName;
        }

        public override void handleGet(System.RestRequest restRequest, System.RestResponse restResponse) {
            this.handleResponse(restRequest, restResponse);
        }

        public override void handlePost(System.RestRequest restRequest, System.RestResponse restResponse) {
            this.handleResponse(restRequest, restResponse);
        }

        private void handleResponse(System.RestRequest restRequest, System.RestResponse restResponse) {
            String errorMessage = 'Unknown endpoint provided: ' + this.endpointName;
            EndpointResponse unknownEndpointResponse = new EndpointResponse(restRequest);
            unknownEndpointResponse.errors.add(new EndpointError(errorMessage));
            restResponse.responseBody = Blob.valueOf(System.JSON.serialize(unknownEndpointResponse, SUPPRESS_NULLS_IN_JSON_SERIALIZATION));
            restResponse.statusCode = 404;

            Nebula.Logger.warn(errorMessage).setRestRequestDetails(restRequest).setRestResponseDetails(restResponse);
            Nebula.Logger.saveLog();
        }
    }
}
