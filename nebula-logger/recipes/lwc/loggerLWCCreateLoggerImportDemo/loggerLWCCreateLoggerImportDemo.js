//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/* eslint-disable no-console */
import { LightningElement, api, wire } from 'lwc';
import returnSomeString from '@salesforce/apex/LoggerLWCDemoController.returnSomeString';
import throwSomeError from '@salesforce/apex/LoggerLWCDemoController.throwSomeError';
import { createLogger } from 'c/logger';

export default class LoggerLWCCreateLoggerImportDemo extends LightningElement {
  @api logger;

  message = 'Hello, world!';
  scenario = 'Some demo scenario';
  someBoolean = false;
  tagsString = 'Tag-one, Another tag here';

  async connectedCallback() {
    /* eslint-disable-next-line @lwc/lwc/no-api-reassignments */
    this.logger = await createLogger();
    console.log('>>> start of connectedCallback()');
    try {
      this.logger.error('test error entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
      this.logger.warn('test warn entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
      this.logger.info('test info entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
      this.logger.debug('test debug entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
      this.logger.fine('test fine entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
      this.logger.finer('test finer entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
      this.logger.finest('test finest entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
      throw new Error('A bad thing happened here');
    } catch (error) {
      this.logger
        .error('>>> connectedCallback error: ' + error.message)
        .setExceptionDetails(error)
        .setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
      this.logger.saveLog().then(() => {
        console.log('done with async save');
      });
    }
  }

  disconnectedCallback() {
    console.log('>>> start of disconnectedCallback()');
    this.logger
      .info('>>> running disconnectedCallback(), using createLogger()')
      .setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
    this.logger.info('>>> adding an extra log entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
    this.logger.saveLog();
    console.log('>>> done with disconnectedCallback()');
  }

  renderedCallback() {
    console.log('>>> start of renderedCallback()');
    this.logger
      ?.info('>>> running renderedCallback(), using createLogger()')
      .setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
    this.logger?.info('>>> adding an extra log entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
    this.logger?.saveLog();
    console.log('>>> done with renderedCallback()');
  }

  @wire(returnSomeString)
  wiredReturnSomeString({ error, data }) {
    this.logger?.info('>>> logging inside a wire function').setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
    if (data) {
      this.logger?.info('>>> wire function return value: ' + data).setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' });
    }
    if (error) {
      this.logger?.error('>>> wire function error: ' + JSON.stringify(error));
    }
  }

  handleRerenderButton() {
    this.someBoolean = !this.someBoolean;
  }

  messageChange(event) {
    this.message = event.target.value;
  }

  scenarioChange(event) {
    this.scenario = event.target.value;
    this.logger.setScenario(this.scenario);
  }

  tagsStringChange(event) {
    this.tagsString = event.target.value;
  }

  async logApexErrorExample() {
    console.log('running logApexError for btn');
    console.log(JSON.parse(JSON.stringify(this.logger)));
    await throwSomeError()
      .then(result => {
        console.log('the result', JSON.parse(JSON.stringify(result)));
      })
      .catch(error => {
        console.log('apex error', error);
        console.log('and a stack trace', new Error().stack);
        const entry = this.logger
          .error(this.message)
          .setExceptionDetails(error)
          .setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' })
          .addTags(this.tagsString.split(','));
        console.log('entry==', JSON.parse(JSON.stringify(entry)));
      });
  }

  logErrorExample() {
    console.log('running logError for btn');
    console.log(this.logger);
    const someError = new TypeError('oops');
    this.logger
      .error(this.message)
      .setExceptionDetails(someError)
      .setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' })
      .addTags(this.tagsString.split(','));
  }

  logWarnExample() {
    console.log('running logWarn for btn');
    console.log(this.logger);
    this.logger.warn(this.message).setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' }).addTags(this.tagsString.split(','));
  }

  logInfoExample() {
    console.log('running logInfo for btn');
    console.log(this.logger);
    this.logger.info(this.message).setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' }).addTags(this.tagsString.split(','));
  }

  logDebugExample() {
    console.log('running logDebug for btn');
    console.log(this.logger);
    this.logger.debug(this.message).setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' }).addTags(this.tagsString.split(','));
  }

  logFineExample() {
    console.log('running logFine for btn');
    console.log(this.logger);
    this.logger.fine(this.message).setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' }).addTags(this.tagsString.split(','));
  }

  logFinerExample() {
    console.log('running logFiner for btn');
    console.log(this.logger);
    this.logger.finer(this.message).setField({ SomeLogEntryField__c: 'some text from loggerLWCCreateLoggerImportDemo' }).addTags(this.tagsString.split(','));
  }

  logFinestExample() {
    console.log('running logFinest for btn');
    console.log(this.logger);
    this.logger.finest(this.message);
  }

  saveLogExample() {
    console.log('running saveLog for btn');
    console.log(this.logger);
    // this.logger.saveLog('QUEUEABLE');
    this.logger.saveLog();
  }
}
