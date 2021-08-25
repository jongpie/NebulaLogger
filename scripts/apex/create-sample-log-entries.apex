Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();

User currentUser = [SELECT Id, Name, Username, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];

new ExampleClassWithLogging().doSomething();

Logger.error('Example ERROR entry', new DmlException('fake DML exception')).addTag('some important tag');
Logger.warn('Something, something, something fake credit card 4000-1111-2222-3333 and something else').addTag('some important tag');
Logger.info('Example INFO entry and in case you want to steal my identity, my fake social is 909-03-4642 thanks').addTag('an informational tag');
Logger.debug('Example DEBUG entry', currentUser);
Logger.fine('Example FINE entry');
Logger.finer('Example FINER entry');
Logger.finest('Example FINEST entry');

Logger.saveLog();
