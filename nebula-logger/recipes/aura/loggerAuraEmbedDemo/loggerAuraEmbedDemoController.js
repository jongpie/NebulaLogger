/* eslint-disable no-console, no-unused-expressions */
({
  saveLogExample: function (component) {
    console.log("start of aura cmp's saveLogExample function");

    const logger = component.find('logger');
    console.log(logger);
    logger.info(component.get('{!v.logMessage}')).setField({ SomeLogEntryField__c: 'some text from loggerAuraEmbedDemo' });
    logger.saveLog();
  }
});
