/* eslint-disable no-console, no-unused-expressions */
({
  afterRender: function (component, helper) {
    this.superAfterRender();
    console.log('Custom renderer afterRender - LWC is now available');

    var logger = component.find('logger');
    if (logger) {
      console.log('the logger from renderer', logger);
      logger.info('INIT - Called from custom renderer afterRender');
      logger.saveLog();
    }
  }
});
