List<Schema.User> users = [SELECT Id, Username, Email, IsActive FROM User LIMIT 5];

System.HttpRequest httpRequest = new System.HttpRequest();
// httpRequest.setBody('Hello, world! Here is an example REST callout request');
httpRequest.setEndpoint('https://jsonplaceholder.typicode.com/todos/1');
httpRequest.setHeader('some-header', 'some value');
httpRequest.setHeader('another-header', 'another value');
httpRequest.setHeader('yet-another-header', 'yet another value');
httpRequest.setMethod('GET');

System.HttpResponse httpResponse = new System.Http().send(httpRequest);

List<Database.SaveResult> databaseResults = System.Database.update(users, false);

System.CalloutException calloutException = new System.CalloutException('This is a test callout exception');

Logger.info('Example of logging an HTTP request & response', users)
    .setExceptionDetails(calloutException)
    .setDatabaseResult(databaseResults)
    .setHttpRequestDetails(httpRequest, new List<String>{ 'some-header' })
    .setHttpResponseDetails(httpResponse);
Logger.saveLog();