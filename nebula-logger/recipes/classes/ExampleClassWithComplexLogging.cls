/**
 * @description An example Apex class for utilizing Nebula Logger.
 */
@SuppressWarnings('PMD.ApexCrudViolation, PMD.ApexDoc')
public with sharing class ExampleClassWithComplexLogging {
    /**
     * @description Default constructor, logs initial message but does not save said log.
     */
    public ExampleClassWithComplexLogging() {
        //
        // Here is an example change to the class.
        // I have added some unnecessary comments,
        // which has changed the line numbers
        // of all of the code below
        // 😭😅
        //
        LogMessage logMessage = new LogMessage('New instance of {0} initialized', ExampleClassWithComplexLogging.class.getName());
        Logger.info(logMessage);
    }

    /**
     * @description Example method for logging that saves log and writes a log entry.
     */
    public LoggerStackTrace doSomething() {
        Logger.info('running doSomething() method!');

        try {
            insertAccount('Some Account Name');
        } catch (Exception ex) {
            Logger.error('An unexpected exception occurred', ex);
            Logger.saveLog();
        }

        LoggerStackTrace stackTrace = new ExampleInnerClass().doAnInnerSomething();

        System.HttpRequest calloutRequest = new System.HttpRequest();
        calloutRequest.setBody('Hello, world!');
        calloutRequest.setCompressed(true);
        Schema.Organization organization = LoggerEngineDataSelector.getInstance().getCachedOrganization();
        String statusApiEndpoint = 'https://api.status.salesforce.com/v1/instances/' + organization.InstanceName + '/status';
        calloutRequest.setEndpoint(statusApiEndpoint);
        calloutRequest.setMethod('GET');

        System.HttpResponse calloutResponse = new System.Http().send(calloutRequest);

        System.RestRequest serviceRequest = new System.RestRequest();
        serviceRequest.httpMethod = 'GET';
        serviceRequest.remoteAddress = '1.1.1.1';
        serviceRequest.requestBody = Blob.valueOf('{hello:"world"}');
        serviceRequest.requestURI = 'some-uri-value';
        serviceRequest.resourcePath = '/some/resource/path';
        serviceRequest.addHeader('some-header', 'some value');
        serviceRequest.addParameter('some-parameter', 'some value');

        System.RestResponse serviceResponse = new System.RestResponse();
        serviceResponse.addHeader('some-header', 'some value');
        serviceResponse.responseBody = Blob.valueOf('{hello:"world"}');
        serviceResponse.statusCode = 200;

        List<Schema.User> users = [SELECT Id, Username, Email, IsActive FROM User LIMIT 5];

        Logger.info('Here is 1 giant log entry, with details for HttpRequest, HttpResponse, RestRequest, and yes, even RestResponse 🥳')
            .setHttpRequestDetails(calloutRequest)
            .setHttpResponseDetails(calloutResponse)
            .setRestRequestDetails(serviceRequest)
            .setRestResponseDetails(serviceResponse)
            .setRecord(users)
            .setDatabaseResult(System.Database.update(users, false))
            .setExceptionDetails(new System.IllegalArgumentException('derp'));

        Logger.saveLog();

        return stackTrace;
    }

    public Schema.Account insertAccount(String accountName) {
        Schema.Account a = new Schema.Account();
        // TODO don't forget to populate account name before deploying this code to prod!
        insert a;
        return a;
    }

    public LoggerStackTrace doAnotherThing() {
        return new LoggerStackTrace();
    }

    /**
     * @description Example inner class.
     */
    public class ExampleInnerClass {
        /**
         * @description Example constructor
         */
        ExampleInnerClass() {
            LogMessage logMessage = new LogMessage('new instance of {0} initialized', ExampleInnerClass.class.getName());
            Logger.info(logMessage);
        }

        /**
         * @description example method in inner class.
         */
        public LoggerStacktrace doAnInnerSomething() {
            Logger.info('running doAnInnerSomething() method!');

            return new LoggerStacktrace();
        }
    }
}
