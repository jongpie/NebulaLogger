Logger.getUserSettings().LoggingLevel__c = LoggingLevel.INFO.name();
Logger.getUserSettings().ApplyDataMaskRules__c = true;

User currentUser = [SELECT Id, Name, Username, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
currentUser.AboutMe = 'I hope you dont leak my social, which is 400-11-9999, btw.';

// new ExampleClassWithLogging().doSomething();


// Logger.error('Example ERROR entry', new DmlException('fake DML exception')).addTag('some important tag');
// Logger.warn('Here is my fake Visa credit card 4000-1111-2222-3333, please don\'t steal it').addTag('data masking rule').addTag('credit card masking');
// Logger.warn('Here is my fake Mastercard credit card 5000-1111-2222-3333, please don\'t steal it').addTag('data masking rule').addTag('credit card masking');
// Logger.warn('Here is my fake Amex credit card 3700 111111 22222, please don\'t steal it').addTag('data masking rule').addTag('credit card masking');
Logger.info('In case you want to steal my identity, my fake social is 400-11-9999, thanks', currentUser).addTag('data masking rule').addTag('an informational tag');
Logger.debug('Example DEBUG entry', currentUser);
Logger.fine('Example FINE entry');
Logger.finer('Example FINER entry');
Logger.finest('Example FINEST entry');

Logger.saveLog();
