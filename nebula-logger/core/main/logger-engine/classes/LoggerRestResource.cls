@RestResource(urlMapping='/logger/*')
global class LoggerRestResource {
    // Possible class names:
    //      - LoggerRestResource
    //      - LoggerResource
    //      - LoggerEndpoint
    //      - LoggerEndpointResource
    //      - LoggerRestService
    //      - LoggerApi
    //      - LoggerRestApi
    //      - LoggerApiService

    /*
        Expected URL structure for endpoints
        - /services/apexrest/logger/v4.13.14/
            - GET: retrieve system info about Nebula Logger + Salesforce org
        - /services/apexrest/logger/v4.13.14/logs
            - POST: create new log + log entries
                - should 'logs' be 'log'
        - /services/apexrest/logger/v4.13.14/logs/some-transaction-id-or-salesforce-id-maybe
            - GET: retrieve Log__c + LogEntry__c + etc
                - optional header in request to specify Salesforce format (default) or OpenTelemetry (OTEL)
    */
    private static final String API_BASE = '/logger/';
    // private static final ApiRequestResolver RESOLVER = new ApiRequestResolver(System.RestContext.request);
    private static final Set<String> VALID_VERSION_NUMBERS = new Set<String>{ 'v1' };
    private static final System.Version INITIAL_RELEASE_VERSION = new System.Version(4, 888, 999);

    public class LogRequest {
        public String parentLogTransactionId;
        public List<LogEntryRequest> logEntries = new List<LogEntryRequest>();
    }

    public class LogEntryRequest {
        // public LogEntryException externalException;
        public String loggingLevelName;
        public String message;
        public Datetime timestamp;
        public List<String> tagNames = new List<String>(); // TODO finalize 'tagNames' vs 'tags'
    }

    // public class LogEntryException {
    //     public String type;
    //     public String message;
    // }

    global class LogResponse {
        // public Boolean isSuccess;
        public String parentLogTransactionId;
        public String transactionId;
        public String saveMethodName;
    }

    @HttpPost
    global static void handlePost() {
        ApiRequestResolver resolver = new ApiRequestResolver(System.RestContext.request);
        // System.Assert.fail('resolver: ' + JSON.serializePretty(resolver));

        switch on resolver.ApiName {
            when 'save' {
                LogResponse logResponse = new LogRequestSaver(System.RestContext.request).saveLogRequest();
                System.RestContext.response = new System.RestResponse();
                System.RestContext.response.responseBody = System.Blob.valueOf(System.JSON.serialize(logResponse));
            }
            when else {
                throw new System.IllegalArgumentException('Unknown endpoint ' + resolver.ApiName);
            }
        }
    }

    // Lovingly borrowed from Joys of Apex - https://www.jamessimone.net/blog/joys-of-apex/extendable-apis/
    public class ApiRequestResolver {
        // private final String apiBase = '/api/';

        public String ApiName { get; private set; }
        public String ApiVersionNumber { get; private set; }
        public String RequestBody { get; private set; }
        // public String RequestUrlBody { get; private set; }

        public ApiRequestResolver(System.RestRequest restRequest) {
            this.validateRequest(restRequest);

            this.ApiName = this.getApiName(restRequest.requestURI);
            this.ApiVersionNumber = this.getApiVersionNumber(restRequest.requestURI);
            this.RequestBody = restRequest.requestBody != null ? restRequest.requestBody.toString() : '';
            // taken straight outta the docs...
            // this.RequestUrlBody = restRequest.requestURI != null ? restRequest.requestURI.substring(restRequest.requestURI.lastIndexOf('/') + 1) : '';
        }

        private void validateRequest(System.RestRequest restRequest) {
            if (String.isBlank(restRequest?.requestURI)) {
                throw new System.IllegalArgumentException('No request URI detected');
            }
        }

        private String getApiName(String requestURI) {
            // Expected format: /services/apexrest/logger/v1/some/other/stuff
            String apiNamePattern = '^/services/apexrest' + API_BASE + '[^/]+/(.+)$';
            System.Matcher matcher = System.Pattern.compile(apiNamePattern).matcher(requestURI);

            // Check if the pattern matches and extract the version
            if (matcher.find()) {
                return matcher.group(1).removeEnd('/').toLowerCase();
            } else {
                throw new System.IllegalArgumentException('No version number specified for logger REST resource');
            }
        }

        private String getApiVersionNumber(String requestURI) {
            // Expected format: /services/apexrest/logger/v1/some/other/stuff
            String apiVersionNumberPattern = '^/services/apexrest' + API_BASE + '([^/]+)/';
            System.Matcher matcher = System.Pattern.compile(apiVersionNumberPattern).matcher(requestURI);

            // Check if the pattern matches and extract the version
            String versionNumber;
            if (matcher.find()) {
                versionNumber = matcher.group(1);
                if (VALID_VERSION_NUMBERS.contains(versionNumber) == false) {
                    throw new System.IllegalArgumentException('Unknown version number specified for logger REST resource: ' + versionNumber);
                }
                return versionNumber;
            } else {
                throw new System.IllegalArgumentException('No version number specified for logger REST resource');
            }
        }
    }

    private class LogRequestSaver {
        private final LogRequest logRequest;

        public LogRequestSaver(System.RestRequest restRequest) {
            this.logRequest = this.deserializeLogRequest(restRequest);
        }

        public LogRequest getLogRequest() {
            return this.logRequest;
        }

        public LogResponse saveLogRequest() {
            LogResponse logResponse = new LogResponse();
            // logResponse.isSuccess = true;
            logResponse.parentLogTransactionId = Logger.getParentLogTransactionId();
            logResponse.transactionId = Logger.getTransactionId();
            logResponse.saveMethodName = Logger.getSaveMethod()?.name() ?? 'Unknown';

            // try {
            Logger.setParentLogTransactionId(this.getLogRequest().parentLogTransactionId);
            for (LogEntryRequest logEntryRequest : this.getLogRequest().logEntries) {
                System.LoggingLevel loggingLevelName = Logger.getLoggingLevel(logEntryRequest.loggingLevelName);
                LogEntryEvent__e logEntryEvent = Logger.newEntry(loggingLevelName, logEntryRequest.message)
                    // .setTimestamp(logEntryRequest.timestamp)
                    .addTags(logEntryRequest.tagNames)
                    .getLogEntryEvent();
                logEntryEvent.OriginType__c = 'Integration';
                logEntryEvent.OriginSourceMetadataType__c = 'Integration';
            }
            Logger.saveLog();
            // } catch (System.Exception ex) {
            //     logResponse.isSuccess = false;
            // }

            return logResponse;
        }

        private LogRequest deserializeLogRequest(System.RestRequest restRequest) {
            if (String.isBlank(restRequest?.requestBody?.toString())) {
                throw new System.IllegalArgumentException('No data provided');
            }

            return (LogRequest) System.JSON.deserialize(restRequest.requestBody.toString(), LogRequest.class);
        }
    }
}
