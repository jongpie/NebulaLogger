System.HttpRequest httpRequest = new System.HttpRequest();
// httpRequest.setBody('Hello, world! Here is an example REST callout request');
httpRequest.setEndpoint('https://jsonplaceholder.typicode.com/todos/1');
httpRequest.setHeader('some-header', 'some value');
httpRequest.setHeader('another-header', 'another value');
httpRequest.setMethod('GET');

System.HttpResponse httpResponse = new System.Http().send(httpRequest);

Logger.info('Example of logging an HTTP request & response')
    .setHttpRequestDetails(httpRequest, new List<String>{ 'some-header' })
    .setHttpResponseDetails(httpResponse);
Logger.saveLog();