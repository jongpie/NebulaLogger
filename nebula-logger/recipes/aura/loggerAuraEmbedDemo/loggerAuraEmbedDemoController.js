/* eslint-disable no-console, no-unused-expressions */
({
  doInit: function (component, event, helper) {
    console.log(">>> start of aura cmp's doInit function");
    // Note: LWC methods are not available yet during doInit
    // Use handleRender instead for LWC interactions
    // $A.createComponent(
    //   'c:logger',
    //   {
    //     'aura:id': 'dynamicLogger'
    //   },
    //   function (newLogger) {
    //     console.log('>>> the newLogger', newLogger);
    //     console.log('>>> component', component);
    //     console.log('>>> component.isValid()', component.isValid());
    //     if (component.isValid()) {
    //       console.log('>>> Dynamic logger created successfully');
    //       newLogger.error('INIT - Created dynamically');
    //       newLogger.saveLog();
    //     }
    //   }
    // );
    // Alternative: Use setTimeout to delay execution
    setTimeout(function () {
      if (component.isValid()) {
        var logger = component.find('logger');
        if (logger && logger.isValid()) {
          console.log('>>> Logger available after timeout');
          logger.info('INIT - Called after setTimeout delay');
          logger.saveLog();
        }
      }
    }, 100); // 100ms delay
  },

  handleRender: function (component, event, helper) {
    console.log(">>> start of aura cmp's handleRender function");

    var logger = component.find('logger');
    console.log('>>> the logger', logger);
    console.log('>>> the logger.error', logger.error);
    logger.error('INIT - Called after render');
    logger.saveLog();
  },

  saveLogExample: function (component) {
    console.log(">>> start of aura cmp's saveLogExample function");

    var logger = component.find('logger');
    console.log(logger);
    logger.info(component.get('{!v.logMessage}')).setField({ SomeLogEntryField__c: 'some text from loggerAuraEmbedDemo' });
    logger.saveLog();
  },

  // Alternative approach using $A.createComponent
  createLoggerDynamically: function (component) {
    console.log('>>> Creating logger dynamically');

    $A.createComponent(
      'c:logger',
      {
        'aura:id': 'dynamicLogger'
      },
      function (newLogger) {
        if (component.isValid()) {
          console.log('>>> Dynamic logger created successfully');
          newLogger.error('INIT - Created dynamically');
          newLogger.saveLog();
        }
      }
    );
  }
});
