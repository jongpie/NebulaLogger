/* eslint-disable no-console, no-unused-expressions */
({
    saveLogExample: function (component) {
        console.log("start of aura cmp's saveLog function");

        const logger = component.find('logger').createLogger();
        console.log(logger);
        logger.fine('Logging from an aura component').addTag('aura cmp');
        const entry = logger.info(component.get('{!v.logMessage}'));
        console.log('stack==' + entry.stack);
        logger.saveLog();
    }
});
