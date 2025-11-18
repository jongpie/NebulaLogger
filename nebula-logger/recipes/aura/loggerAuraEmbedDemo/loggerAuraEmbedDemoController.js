/* eslint-disable no-console, no-unused-expressions */
({
  saveLogExample: function (component) {
    console.log("start of aura cmp's saveLogExample function");

    var customError = new Error('custom error');
    console.log('>>> customError==', JSON.parse(JSON.stringify(customError)));
    console.log('>>> customError.stack==', JSON.parse(JSON.stringify(customError.stack)));

    var logger = component.find('logger');
    console.log(logger);
    logger.info(component.get('{!v.logMessage}')).setField({ SomeLogEntryField__c: 'some text from loggerAuraEmbedDemo' });
    logger.saveLog();
  }
});
