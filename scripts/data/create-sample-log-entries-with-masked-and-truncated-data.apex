Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.INFO.name();
Logger.getUserSettings().IsDataMaskingEnabled__c = true;

String fakeCreditCardText = 'Here is my fake Visa credit card 4000-1111-2222-0004, please don\'t steal it';
String fakeSocialSecurityNumberText = 'I hope you dont leak my social, which is 400-11-9999, btw.';

System.HttpRequest calloutRequest = new System.HttpRequest();
calloutRequest.setBody('Hello, world! ' + fakeSocialSecurityNumberText +'A'.repeat(LogEntryEvent__e.HttpResponseBody__c.getDescribe().getLength()));
calloutRequest.setCompressed(true);
Schema.Organization organization = LoggerEngineDataSelector.getInstance().getCachedOrganization();
String statusApiEndpoint = 'https://api.status.salesforce.com/v1/instances/' + organization.InstanceName + '/status';
calloutRequest.setEndpoint(statusApiEndpoint);
calloutRequest.setMethod('GET');

System.HttpResponse calloutResponse = new System.Http().send(calloutRequest);
calloutResponse.setBody(calloutResponse.getBody() + 'A'.repeat(LogEntryEvent__e.HttpResponseBody__c.getDescribe().getLength()));

System.RestRequest serviceRequest = new System.RestRequest();
serviceRequest.httpMethod = 'GET';
serviceRequest.remoteAddress = '1.1.1.1';
serviceRequest.requestBody = Blob.valueOf('{hello:"world", "longValue": "' + fakeSocialSecurityNumberText + 'A'.repeat(LogEntryEvent__e.RestRequestBody__c.getDescribe().getLength()) + '"}');
serviceRequest.requestURI = 'some-uri-value';
serviceRequest.resourcePath = '/some/resource/path';
serviceRequest.addHeader('some-header', 'some value');
serviceRequest.addParameter('some-parameter', 'some value');

System.RestResponse serviceResponse = new System.RestResponse();
serviceResponse.addHeader('some-header', 'some value');
serviceResponse.responseBody = Blob.valueOf('{hello:"world", "longValue": "' + fakeCreditCardText + 'A'.repeat(LogEntryEvent__e.RestResponseBody__c.getDescribe().getLength()) + '"}');
serviceResponse.statusCode = 200;

List<Schema.User> users = [SELECT Id, Username, Email, IsActive FROM User LIMIT 5];
users.get(0).LastName = fakeSocialSecurityNumberText + 'A'.repeat(LogEntryEvent__e.RecordJson__c.getDescribe().getLength());

Logger.info('Here is 1 giant log entry, with details for HttpRequest, HttpResponse, RestRequest, and yes, even RestResponse 🥳\n\n' + fakeCreditCardText + 'A'.repeat(LogEntryEvent__e.Message__c.getDescribe().getLength()))
    .setHttpRequestDetails(calloutRequest)
    .setHttpResponseDetails(calloutResponse)
    .setRestRequestDetails(serviceRequest)
    .setRestResponseDetails(serviceResponse)
    .setRecord(users)
    .setDatabaseResult(System.Database.update(users, false))
    .setExceptionDetails(new System.IllegalArgumentException('derp'));

Logger.saveLog();
