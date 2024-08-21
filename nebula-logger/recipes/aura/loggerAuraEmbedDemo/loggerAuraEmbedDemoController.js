/* eslint-disable no-console, no-unused-expressions */
({
  saveLogExample: function (component) {
    console.log("start of aura cmp's saveLog function");

    const logger = component.find('logger');
    console.log(logger);
    logger.info(component.get('{!v.logMessage}'));
    logger.saveLog();
  }
});
