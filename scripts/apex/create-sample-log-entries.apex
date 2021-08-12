Logger.getUserSettings().LoggingLevel__c = LoggingLevel.FINEST.name();

User currentUser = [SELECT Id, Name, Username, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];

new ExampleClassWithLogging().doSomething();

Logger.error('Add log entry using Nebula Logger with logging level == ERROR', new DmlException('fake DML exception')).addTag('some important tag');
Logger.warn('Add log entry using Nebula Logger with logging level == WARN', currentUser).addTag('some important tag');
Logger.info('Add log entry using Nebula Logger with logging level == INFO');
Logger.debug('Add log entry using Nebula Logger with logging level == DEBUG', currentUser);
Logger.fine('Add log entry using Nebula Logger with logging level == FINE');
Logger.finer('Add log entry using Nebula Logger with logging level == FINER');
Logger.finest('Add log entry using Nebula Logger with logging level == FINEST');

Logger.saveLog();
