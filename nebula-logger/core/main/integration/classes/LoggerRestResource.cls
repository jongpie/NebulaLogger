@RestResource(urlMapping='/logger/*')
global class LoggerRestResource {
    // TODO revisit this value / confirm how it will behave with a namespace
    @TestVisible
    private static final String REQUEST_URI_BASE = '/services/apexrest/logger';

    @HttpGet
    global static void handleGet() {
        // TODO revisit this line
        System.RestContext.response = System.RestContext.response ?? new System.RestResponse();
        System.RestContext.response.addHeader('Content-Type', 'application/json');

        RequestResolver requestResolver = new RequestResolver(System.RestContext.request);
        switch on requestResolver.getEndpoint() {
            // when '/log' {
            //     new LogCreateRequestSaver().respond(System.RestContext.request, System.RestContext.response);
            // }
            when else {
                new UnknownEndpointResponder(requestResolver).respond(System.RestContext.request, System.RestContext.response);
            }
        }
    }

    @HttpPost
    global static void handlePost() {
        // TODO revisit this line
        System.RestContext.response = System.RestContext.response ?? new System.RestResponse();
        System.RestContext.response.addHeader('Content-Type', 'application/json');

        RequestResolver requestResolver = new RequestResolver(System.RestContext.request);
        switch on requestResolver.getEndpoint() {
            when '/log' {
                new LogCreateRequestSaver().respond(System.RestContext.request, System.RestContext.response);
            }
            when else {
                new UnknownEndpointResponder(requestResolver).respond(System.RestContext.request, System.RestContext.response);
            }
        }
    }

    /* Base classes for requests & responses */
    public virtual class EndpointResponse {
        public String endpoint;
        public List<EndpointError> errors = new List<EndpointError>();
        public String requestId;
        public String transactionId;

        public Boolean isSuccess {
            get {
                return this.errors.isEmpty();
            }
        }

        public EndpointResponse() {
            this.requestId = System.Request.getCurrent().getRequestId();
            this.transactionId = Nebula.Logger.getTransactionId();
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

    /* start of '/log' endpoint POST classes */
    public class LogCreateRequest {
        public List<LogEntryCreateRequest> logEntries = new List<LogEntryCreateRequest>();
        public String parentLogTransactionId;
        public String scenario;
    }

    public class LogEntryCreateRequest {
        public String loggingLevel;
        public String message;
        public String relatedRecordId;
        public List<String> tags = new List<String>();
        public Datetime timestamp;
    }
    /* end of '/log' endpoint POST classes */

    private class RequestResolver {
        private final System.RestRequest restRequest;

        private String endpoint;

        public RequestResolver(System.RestRequest restRequest) {
            this.restRequest = restRequest;
        }

        public String getEndpoint() {
            if (this.endpoint == null) {
                // TODO decide if anything else needs to be trimmed (trailing whitespace, trailing slash '/', trailing '?', etc.)
                String parsedEndpoint = this.restRequest.requestUri.substringAfter(REQUEST_URI_BASE);
                if (parsedEndpoint.contains('?')) {
                    parsedEndpoint = parsedEndpoint.substringBefore('?');
                }
                this.endpoint = parsedEndpoint.removeEnd('/');
            }
            return this.endpoint;
        }
    }

    private abstract class RequestResponder {
        abstract void respond(System.RestRequest restRequest, System.RestResponse restResponse);
    }

    private class LogCreateRequestSaver extends RequestResponder {
        public LogCreateRequestSaver() {
            // No-op for now
        }

        public override void respond(System.RestRequest restRequest, System.RestResponse restResponse) {
            EndpointResponse endpointResponse = new EndpointResponse();
            try {
                this.saveLogRequest(restRequest);
                restResponse.statusCode = 200;
                restResponse.responseBody = System.Blob.valueOf(System.JSON.serialize(endpointResponse));
            } catch (Exception apexException) {
                Nebula.Logger.error('Failed to save external log', apexException).setRestRequestDetails(restRequest).setRestResponseDetails(restResponse);
                Nebula.Logger.saveLog();

                endpointResponse.errors.add(new EndpointError(apexException));
                restResponse.statusCode = 400;
                restResponse.responseBody = System.Blob.valueOf(System.JSON.serialize(endpointResponse));
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
                    .addTags(logEntryCreateRequest.tags);

                // FIXME The managed package currently doesn't have the .setTimestamp() builder method,
                // so there's not a great way to correctly set the Timestamp__c field yet
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

    private class UnknownEndpointResponder extends RequestResponder {
        private final RequestResolver requestResolver;

        public UnknownEndpointResponder(RequestResolver requestResolver) {
            this.requestResolver = requestResolver;
        }

        public override void respond(System.RestRequest restRequest, System.RestResponse restResponse) {
            EndpointResponse unknownEndpointResponse = new EndpointResponse();
            String errorMessage = 'Unknown endpoint provided: ' + this.requestResolver.getEndpoint();
            unknownEndpointResponse.errors.add(new EndpointError(errorMessage));
            restResponse.statusCode = 404;
            restResponse.responseBody = System.Blob.valueOf(System.JSON.serialize(unknownEndpointResponse));
        }
    }
}
