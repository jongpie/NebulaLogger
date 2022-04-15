Logger.getUserSettings().DefaultSaveMethod__c = Logger.SaveMethod.EVENT_BUS.name();
// Logger.getUserSettings().DefaultSaveMethod__c = 'BIG_OBJECT_IMMEDIATE';
// Logger.getUserSettings().DefaultSaveMethod__c = 'BIG_OBJECT_QUEUEABLE';
// Logger.getUserSettings().IsAnonymousModeEnabled__c = true;
Logger.getUserSettings().DefaultPlatformEventStorageLocation__c = 'BIG_OBJECT';
upsert Logger.getUserSettings();

Logger.setScenario('an example transaction scenario name');
Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();
Logger.getUserSettings().IsDataMaskingEnabled__c = true;

User currentUser = [SELECT Id, Name, Username, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
currentUser.AboutMe = 'I hope you dont leak my social, which is 400-11-9999, btw.';

// new ExampleClassWithLogging().doSomething();


// Logger.error('Example ERROR entry', new DmlException('fake DML exception')).addTag('some important tag');
Logger.error('Here is my fake Visa credit card 4000-1111-2222-0004, please don\'t steal it').addTag('data masking rule').addTag('credit card masking');
Logger.warn('Here is my fake Mastercard credit card 5000-1111-2222-0005, please don\'t steal it').addTag('data masking rule').addTag('credit card masking');
Logger.info('In case you want to steal my identity, my fake social is 400-11-9999, thanks', currentUser).addTag('data masking rule').addTag('an informational tag');
Logger.debug('Here are some accounts', [SELECT Id, Name, Description FROM Account LIMIT 5]);
Logger.debug('Here are some save results', Database.update([SELECT Id, Name, Description FROM Account LIMIT 5], false));
Logger.saveLog();
Logger.debug('Example DEBUG entry', currentUser);
Logger.fine('Example FINE entry');
Logger.finer('Example FINER entry');
Logger.finest('Example FINEST entry');

Logger.saveLog();

throw new DmlException('aahhhhh!');
