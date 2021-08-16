({
    logSomething : function(component, event, helper) {
        var logger = component.find('logger');
        logger.info('Logging from an aura component').addTag('aura cmp');
        logger.save();
    }
})
