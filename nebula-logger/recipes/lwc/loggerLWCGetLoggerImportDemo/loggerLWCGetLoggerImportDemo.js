//------------------------------------------------------------------------------------------------//
// This file is part of the Nebula Logger project, released under the MIT License.                //
// See LICENSE file or go to https://github.com/jongpie/NebulaLogger for full license details.    //
//------------------------------------------------------------------------------------------------//

/* eslint-disable no-console */
import { LightningElement, wire } from 'lwc';
import returnSomeString from '@salesforce/apex/LoggerLWCDemoController.returnSomeString';
import throwSomeError from '@salesforce/apex/LoggerLWCDemoController.throwSomeError';
import { getLogger } from 'c/logger';

export default class LoggerLWCGetLoggerImportDemo extends LightningElement {
  someBoolean = false;

  message = 'Hello, world!';
  scenario = 'Some demo scenario';
  tagsString = 'Tag-one, Another tag here';
  logger = getLogger();

  connectedCallback() {
    try {
      this.logger.error('test error entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
      this.logger.warn('test warn entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
      this.logger.info('test info entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
      this.logger.debug('test debug entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
      this.logger.fine('test fine entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
      this.logger.finer('test finer entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
      this.logger.finest('test finest entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
      throw new Error('A bad thing happened here');
    } catch (error) {
      this.logger
        .error('>>> connectedCallback error: ' + error.message)
        .setExceptionDetails(error)
        .setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
    } finally {
      this.logger.saveLog();
    }
  }

  // This disconnectedCallback doesn't need to be async, but running it as async demonstrates
  // that there is still an ongoing challenge of getting an accurate function name (`disconnectedCallback`, in this case)
  // when running in an async context.
  //    - This challenge is due to how stack traces are handled in some browsers (especially webkit browsers like Chrome & Edge),
  //      it's not specific to Nebula Logger or Salesforce
  //    - In those browsers, error stack traces in async functions only contain `eval` for the function name - in an LWC
  //      with an async function, like `async connecectedCallback()`, the stack traces do not contain `disconnectedCallback` anywhere
  //      so it's impossible to get the function name using only JS error stack traces
  //    - This may be further addressed in the future, but for now, it's considered a known limitation
  async disconnectedCallback() {
    console.log('>>> start of disconnectedCallback()');
    this.logger.info('>>> running disconnectedCallback(), using getLogger()').setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
    this.logger.info('>>> adding an extra log entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
    this.logger.saveLog();
    console.log('>>> done with disconnectedCallback()');
  }

  renderedCallback() {
    console.log('>>> start of renderedCallback()');
    this.logger.info('>>> running renderedCallback(), using getLogger()').setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
    this.logger.info('>>> adding an extra log entry').setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
    this.logger.saveLog();
    console.log('>>> done with renderedCallback()');
  }

  @wire(returnSomeString)
  wiredReturnSomeString({ error, data }) {
    this.logger.info('>>> logging inside a wire function').setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
    if (data) {
      this.logger.info('>>> wire function return value: ' + data).setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' });
    }
    if (error) {
      this.logger.error('>>> wire function error: ' + JSON.stringify(error));
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
          .setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' })
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
      .setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' })
      .addTags(this.tagsString.split(','));
  }

  logWarnExample() {
    console.log('running logWarn for btn');
    console.log(this.logger);
    this.logger.warn(this.message).setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' }).addTags(this.tagsString.split(','));
  }

  logInfoExample() {
    console.log('running logInfo for btn');
    console.log(this.logger);
    this.logger.info(this.message).setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' }).addTags(this.tagsString.split(','));
  }

  logDebugExample() {
    console.log('running logDebug for btn');
    console.log(this.logger);
    this.logger.debug(this.message).setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' }).addTags(this.tagsString.split(','));
  }

  logFineExample() {
    console.log('running logFine for btn');
    console.log(this.logger);
    this.logger.fine(this.message).setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' }).addTags(this.tagsString.split(','));
  }

  logFinerExample() {
    console.log('running logFiner for btn');
    console.log(this.logger);
    this.logger.finer(this.message).setField({ SomeLogEntryField__c: 'some text from loggerLWCGetLoggerImportDemo' }).addTags(this.tagsString.split(','));
  }

  logFinestExample() {
    console.log('running logFinest for btn');
    console.log(this.logger);
    this.logger.finest(this.message);
  }

  saveLogExample() {
    console.log('running saveLog for btn');
    this.logger.setScenario(this.scenario);
    console.log(this.logger);
    // this.logger.saveLog('QUEUEABLE');
    this.logger.saveLog();
  }
}
