Logger.getUserSettings().DefaultSaveMethod__c = 'BIG_OBJECT';
//Logger.getUserSettings().IsAnonymousModeEnabled__c = true;

for (Integer i = 0; i < 10; i++) {
    Logger.info('hello, LogEntryArchive__b! entry index==' + i).addTag('test tag');
}

try {
    Logger.debug('about to cause an exception').addTag('error logging');
    update new User();
} catch(Exception ex) {
    Logger.error('got that exception that everyone was talking about, wild stuff', ex).addTag('error logging');
    Logger.saveLog();
    throw ex;
}
