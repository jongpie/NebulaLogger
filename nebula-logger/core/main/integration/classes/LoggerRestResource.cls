@RestResource(urlMapping='/logger/*')
global class LoggerRestResource {
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

    @HttpPost
    global static void handlePost() {
        System.RestContext.response = initializeRestResponse();
        String endpointName = getEndpointName(System.RestContext.request);

        switch on endpointName {
            when 'log' {
                new LogEndpoint().handlePost(System.RestContext.request, System.RestContext.response);
            }
            when else {
                new UnknownEndpointResponder(endpointName).handlePost(System.RestContext.request, System.RestContext.response);
            }
        }
    }

    private static String getEndpointName(System.RestRequest restRequest) {
        /*
             Endpoint names will (at least for now) only have one layer, using formats like:
             /logger/log
             /logger/log/?some-url-parameter=true&and-another=true
             /logger/something
             /logger/something?another-url-parameter=something
             /Nebula/logger/log
             /Nebula/logger/log/?some-url-parameter=true&and-another=true
             /Nebula/logger/something
             /Nebula/logger/something?another-url-parameter=something

             The endpoint name will be just the last bit of the URL, without any parameters or '/' slashes.
             So if the URL is:
                /logger/something?some-url-parameter=true&and-another=true
             then the endpoint name will be 'something'

        */
        String parsedEndpoint = restRequest.requestUri.substringAfter(REQUEST_URI_BASE);
        if (parsedEndpoint.contains('?')) {
            parsedEndpoint = parsedEndpoint.substringBefore('?');
        }
        return parsedEndpoint.removeStart('/').removeEnd('/');
    }

    private static System.RestResponse initializeRestResponse() {
        System.RestResponse restResponse = System.RestContext.response ?? new System.RestResponse();
        restResponse.addHeader('Content-Type', 'application/json');
        return restResponse;
    }

    /* Base classes for REST responses returned by all endpoints */
    public virtual class EndpointResponse {
        public String endpoint;
        public List<EndpointError> errors = new List<EndpointError>();
        public EndpointLoggerContext logger = new EndpointLoggerContext();
        public EndpointOrganizationContext organization = new EndpointOrganizationContext();
        public String requestId = System.Request.getCurrent().getRequestId();
        public String transactionId = Nebula.Logger.getTransactionId();
        public EndpointUserContext user = new EndpointUserContext();

        public Boolean isSuccess {
            get {
                return this.errors.isEmpty();
            }
        }
    }

    public virtual class EndpointError {
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
        public String versionNumber = Nebula.Logger.getVersionNumber();
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
        public String type = System.UserInfo.getUserType();
        public String username = System.UserInfo.getUsername();
    }

    private abstract class Endpoint {
        // For now, only POST is used by Nebula Logger, so there's no need to have methods
        // for the other HTTP verbs DELETE, GET PATCH, and PUT.
        public virtual void handlePost(System.RestRequest restRequest, System.RestResponse restResponse) {
            throw new System.IllegalArgumentException('Unsupported method: ' + restRequest.httpMethod);
        }
    }

    /* start of '/log' endpoint classes */
    @TestVisible
    private class LogCreateRequest {
        public List<LogEntryCreateRequest> logEntries = new List<LogEntryCreateRequest>();
        public String parentLogTransactionId;
        public String scenario;
    }

    @TestVisible
    private class LogEntryCreateRequest {
        public String loggingLevel;
        public String message;
        public String relatedRecordId;
        public List<String> tags = new List<String>();
        public Datetime timestamp;
    }

    @TestVisible
    private class LogEntryCreateResponse extends EndpointResponse {
        // TODO add details about Logger.bufferSize(), save method, scenario, etc.
        public LogCreateSummary log = new LogCreateSummary();
    }

    private class LogCreateSummary {
        public Integer logEntriesSent;
        public Integer logEntriesSaved;
        public String saveMethod;
    }
    /* end of '/log' endpoint classes */

    private class LogEndpoint extends Endpoint {
        public override void handlePost(System.RestRequest restRequest, System.RestResponse restResponse) {
            try {
                this.saveLogRequest(restRequest);

                restResponse.responseBody = Blob.valueOf(System.JSON.serialize(new EndpointResponse(), SUPPRESS_NULLS_IN_JSON_SERIALIZATION));
                restResponse.statusCode = 200;
            } catch (Exception apexException) {
                Nebula.Logger.error('Failed to save external log', apexException).setRestRequestDetails(restRequest).setRestResponseDetails(restResponse);
                Nebula.Logger.saveLog();

                EndpointResponse endpointResponse = new LogEntryCreateResponse();
                endpointResponse.errors.add(new EndpointError(apexException));
                restResponse.responseBody = Blob.valueOf(System.JSON.serialize(endpointResponse, SUPPRESS_NULLS_IN_JSON_SERIALIZATION));
                restResponse.statusCode = 400;
            }
        }

        private void saveLogRequest(System.RestRequest restRequest) {
            LogCreateRequest logCreateRequest = this.deserializeLogRequest(restRequest);
            Nebula.Logger.setParentLogTransactionId(logCreateRequest.parentLogTransactionId);
            Nebula.Logger.setScenario(logCreateRequest.scenario);
            for (LogEntryCreateRequest logEntryCreateRequest : logCreateRequest.logEntries) {
                System.LoggingLevel loggingLevel = Nebula.Logger.getLoggingLevel(logEntryCreateRequest.loggingLevel);
                Nebula.Logger.newEntry(loggingLevel, logEntryCreateRequest.message)
                    .setRecord(logEntryCreateRequest.relatedRecordId)
                    // FIXME The managed package currently doesn't have the .setTimestamp() builder method,
                    // so there's not a great way to correctly set the Timestamp__c field yet
                    // .setTimestamp(logEntryCreateRequest.timestamp)
                    .addTags(logEntryCreateRequest.tags);
            }
            Nebula.Logger.saveLog();
        }

        private LogCreateRequest deserializeLogRequest(System.RestRequest restRequest) {
            if (String.isBlank(restRequest?.requestBody?.toString())) {
                throw new System.IllegalArgumentException('No data provided');
            }

            LogCreateRequest logCreateRequest = (LogCreateRequest) System.JSON.deserialize(restRequest.requestBody.toString(), LogCreateRequest.class);

            if (logCreateRequest.logEntries == null || logCreateRequest.logEntries.isEmpty()) {
                throw new System.IllegalArgumentException('No log entries provided');
            }

            return logCreateRequest;
        }
    }
    /* end of '/log' endpoint classes */

    private class UnknownEndpointResponder extends Endpoint {
        private final String endpointName;

        public UnknownEndpointResponder(String endpointName) {
            this.endpointName = endpointName;
        }

        // public override void handleGet(System.RestRequest restRequest, System.RestResponse restResponse) {
        //     this.buildEndpointResponse(restResponse);
        // }

        public override void handlePost(System.RestRequest restRequest, System.RestResponse restResponse) {
            this.buildEndpointResponse(restResponse);
        }

        private void buildEndpointResponse(System.RestResponse restResponse) {
            String errorMessage = 'Unknown endpoint provided: ' + this.endpointName;
            EndpointResponse unknownEndpointResponse = new EndpointResponse();
            unknownEndpointResponse.errors.add(new EndpointError(errorMessage));
            restResponse.responseBody = Blob.valueOf(System.JSON.serialize(unknownEndpointResponse, SUPPRESS_NULLS_IN_JSON_SERIALIZATION));
            restResponse.statusCode = 404;
        }
    }
}
