
LoggerStackTrace.ignoreOrigins(new Set<System.Type>{ Logger.class, LogEntryEventBuilder.class, LogMessage.class});
// Logger.getUserSettings().DefaultSaveMethod__c = Logger.SaveMethod.SYNCHRONOUS_DML.name();

// Logger.getUserSettings().DefaultSaveMethod__c = Logger.SaveMethod.EVENT_BUS.name();
// Logger.getUserSettings().DefaultSaveMethod__c = 'BIG_OBJECT_IMMEDIATE';
// Logger.getUserSettings().DefaultSaveMethod__c = 'BIG_OBJECT_QUEUEABLE';
// Logger.getUserSettings().IsAnonymousModeEnabled__c = true;
// Logger.getUserSettings().DefaultPlatformEventStorageLocation__c = 'BIG_OBJECT';
// Logger.getUserSettings().DefaultPlatformEventStorageLocation__c = 'CUSTOM_OBJECTS';
// upsert Logger.getUserSettings();

Logger.setScenario('an example transaction scenario name');
Logger.getUserSettings().LoggingLevel__c = System.LoggingLevel.FINEST.name();
Logger.getUserSettings().IsDataMaskingEnabled__c = true;

Schema.User currentUser = [SELECT Id, Name, Username, Profile.Name FROM User WHERE Id = :System.UserInfo.getUserId()];
currentUser.AboutMe = 'I hope you dont leak my social, which is 400-11-9999, btw.';

new ExampleClassWithLogging().doSomething();
new ExampleClassWithLogging().insertAccount('some account name');

// Logger.error('Example ERROR entry', new DmlException('fake DML exception')).addTag('some important tag');
Logger.error('Here is my fake Visa credit card 4000-1111-2222-0004, please don\'t steal it').addTag('data masking rule').addTag('credit card masking');
Logger.warn('Here is my fake Mastercard credit card 5000-1111-2222-0005, please don\'t steal it').addTag('data masking rule').addTag('credit card masking');
Logger.info('In case you want to steal my identity, my fake social is 400-11-9999, thanks', currentUser)
    .addTag('data masking rule')
    .addTag('an informational tag');
Logger.debug('Here are some accounts', [SELECT Id, Name, Description FROM Account LIMIT 5]);
Logger.debug('Here are some save results', Database.update([SELECT Id, Name, Description FROM Account LIMIT 5], false));
Logger.saveLog();
Logger.debug('Example DEBUG entry', currentUser);
Logger.fine('Example FINE entry');
Logger.finer('Example FINER entry');
Logger.finest('Example FINEST entry');

System.HttpRequest request = new System.HttpRequest();
request.setBody('Hello, world! Here is my credit card number 5000-1111-2222-0005');
request.setEndpoint('https://fake.salesforce.com');
request.setMethod('GET');
Logger.info('logging an HTTP request').setHttpRequestDetails(request);

System.HttpResponse response = new System.HttpResponse();
response.setBody('Hello, world! Here is my credit card number 5000-1111-2222-0005');
response.setHeader('someKey', 'some string value');
response.setHeader('anotherKey', 'an amazing example value, wow');
response.setStatus('STATUS_GOOD_JOB_YOU_DID_IT');
response.setStatusCode(201);
Logger.info('logging an HTTP response').setHttpResponseDetails(response);

Logger.saveLog();

// throw new System.DmlException('aahhhhh!');
